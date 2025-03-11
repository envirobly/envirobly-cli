require "aws-sdk-s3"
require "zlib"
require "open3"
require "concurrent"

class Envirobly::Aws::S3
  def initialize(bucket)
    @bucket = bucket
    @client = Aws::S3::Client.new # TODO: region and creds should be passed
  end

  def push(commit)
    puts "Pushing #{commit.ref} to #{@bucket}"
    object_hashes = commit.object_tree.map { |object| object[:hash] }
    # upload_git_objects object_hashes
    compress_and_upload_object object_hashes.first
  end

  private
    def object_exists?(key)
      @client.head_object(bucket: @bucket, key:)
      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    def compress_and_upload_object(git_object_hash)
      Tempfile.create(["envirobly-push", ".gz"]) do |tempfile|
        Zlib::GzipWriter.open(tempfile.path) do |gz|
          Open3.popen3("git", "ls-tree", "-r", "HEAD") do |stdin, stdout, stderr, thread|
            while line = stdout.gets
              gz.write(line)
            end

            unless thread.value.success?
              raise "git ls-tree failed: #{stderr.read}"
            end
          end
        end

        # Print the path of the resulting file (optional)
        puts "Compressed file created at: #{tempfile.path}"

        key = "git-objects/#{git_object_hash}.gz"
        resp = @client.put_object(bucket: @bucket, body: tempfile.path, key:)
        puts resp.to_h
        puts "Git object #{git_object_hash} uploaded as #{key} with gzip compression"
      end
    end

    def upload_git_objects(object_hashes, thread_count: 6)
      pool = Concurrent::FixedThreadPool.new(thread_count)

      object_hashes.each do |hash|
        pool.post do
          key = "git-objects/#{hash}.gz"
          puts "Object exists: #{object_exists?(key)}"
          sleep 0.5
        end
      end

      # tell the pool to shutdown in an orderly fashion, allowing in progress work to complete
      pool.shutdown
      # now wait for all work to complete, wait as long as it takes
      pool.wait_for_termination

      # # Track upload status using Promise
      # promises = object_hashes.map do |hash|
      #   Concurrent::Promise.new(executor: executor) do
      #     key = "git-objects/#{hash}.gz"
      #     puts key
      #     sleep 2

      #     # if object_exists?(key)
      #     #   puts "Skipping #{hash}: already exists in S3"
      #     #   next hash # Resolve promise with hash to count as completed
      #     # end

      #     # # Open git cat-file process
      #     # stdin, stdout, stderr, wait_thr = Open3.popen3("git cat-file -p #{hash}")

      #     # begin
      #     #   # Create pipe for streaming
      #     #   reader, writer = IO.pipe

      #     #   # Start S3 upload in a separate thread
      #     #   upload_future = Concurrent::Future.execute(executor: executor) do
      #     #     @client.put_object(
      #     #       bucket: @bucket,
      #     #       key: key,
      #     #       body: reader,
      #     #       content_encoding: 'gzip'
      #     #     )
      #     #   end

      #     #   # Compress and stream
      #     #   Zlib::GzipWriter.open(writer) do |gz|
      #     #     IO.copy_stream(stdout, gz)
      #     #   end

      #     #   # Close writer and wait for upload
      #     #   writer.close
      #     #   upload_future.value # Blocks until upload completes

      #     #   # Return hash on success
      #     #   hash
      #     # rescue StandardError => e
      #     #   puts "Error uploading #{hash}: #{e.message}"
      #     #   e.backtrace.each { |line| puts line }
      #     #   raise # Re-raise to mark promise as failed
      #     # ensure
      #     #   # Clean up resources
      #     #   stdin&.close
      #     #   stdout&.close
      #     #   stderr&.close
      #     #   wait_thr&.kill if wait_thr&.alive?
      #     # end
      #   end
      # end

      # # Execute all promises and track progress
      # total = object_hashes.length
      # completed = 0

      # # Wait for all promises to complete
      # Concurrent::Promise.zip(*promises).then do |results|
      #   results.each do |result|
      #     if result.fulfilled?
      #       completed += 1
      #       puts "Progress: #{completed}/#{total} (#{((completed.to_f/total) * 100).round}%)"
      #     end
      #   end
      # end.wait

      # executor.shutdown
      # executor.wait_for_termination
    end
end
