require "aws-sdk-s3"
require "zlib"
require "open3"
require "concurrent"
require "benchmark"

class Envirobly::Aws::S3
  def initialize(bucket)
    @bucket = bucket
    @client = Aws::S3::Client.new # TODO: region and creds should be passed
  end

  def push(commit)
    puts "Pushing commit #{commit.ref} to #{@bucket}"

    object_hashes = commit.object_tree.map { |object| object[:hash] }

    timings = Benchmark.measure do
      upload_git_objects object_hashes
    end
    puts "Took #{format_duration timings.real}"
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
          Open3.popen3("git", "cat-file", "-p", git_object_hash) do |stdin, stdout, stderr, thread|
            IO.copy_stream(stdout, gz)

            unless thread.value.success?
              raise "`git cat-file -p #{git_object_hash}` failed: #{stderr.read}"
            end
          end
        end

        key = "git-objects/#{git_object_hash}.gz"
        resp = @client.put_object(bucket: @bucket, body: tempfile, key:)
        # puts resp.to_h
        puts "⤴ #{key}"
      end
    end

    def upload_git_objects(object_hashes, thread_count: 6)
      pool = Concurrent::FixedThreadPool.new(thread_count)

      object_hashes.each do |object_hash|
        pool.post do
          compress_and_upload_object object_hash
        end
      end

      # tell the pool to shutdown in an orderly fashion, allowing in progress work to complete
      pool.shutdown
      # now wait for all work to complete, wait as long as it takes
      pool.wait_for_termination
    end

    def format_duration(duration)
      total_seconds = duration.to_i
      minutes = (total_seconds / 60).floor
      seconds = (total_seconds % 60).ceil
      result = [ "#{seconds}s" ]
      result.prepend "#{minutes}m" if minutes > 0
      result.join " "
    end
end
