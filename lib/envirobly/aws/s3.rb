require "zlib"
require "json"
require "open3"
require "benchmark"
require "concurrent"
require "aws-sdk-s3"

class Envirobly::Aws::S3
  OBJECTS_PREFIX = "blobs"
  MANIFESTS_PREFIX = "manifests"
  CONCURRENCY = 6

  def initialize(bucket:, region:, credentials: nil)
    @region = region
    @bucket = bucket

    client_options = { region: }
    unless credentials.nil?
      client_options.merge! credentials.transform_keys(&:to_sym)
    end

    @client = Aws::S3::Client.new(client_options)
    resource = Aws::S3::Resource.new(client: @client)
    @bucket_resource = resource.bucket(@bucket)
  end

  def push(commit)
    if object_exists?(manifest_key(commit.ref))
      # puts "Commit #{commit.ref} build context is already uploaded."
      return
    end

    # puts "Pushing commit #{commit.ref} to #{@bucket}"

    timings = Benchmark.measure do
      manifest = []
      objects_count = 0
      objects_to_upload = []
      remote_object_hashes = list_object_hashes

      commit.object_tree.each do |chdir, objects|
        objects.each do |(mode, type, object_hash, path)|
          objects_count += 1
          path = File.join chdir.delete_prefix(commit.working_dir), path
          manifest << [ mode, type, object_hash, path.delete_prefix("/") ]

          next if remote_object_hashes.include?(object_hash)
          objects_to_upload << [ chdir, object_hash ]
        end
      end

      puts "Uploading #{objects_to_upload.size} out of #{objects_count} build context files"
      upload_git_objects(objects_to_upload)
      upload_manifest manifest_key(commit.ref), manifest
    end

    puts "Upload done in #{format_duration timings.real}"
  end

  def pull(commit_ref, target_dir)
    puts "Pulling #{commit_ref} into #{target_dir}"

    timings = Benchmark.measure do
      manifest = fetch_manifest(commit_ref)
      FileUtils.mkdir_p(target_dir)

      puts "Downloading #{manifest.size} files"
      pool = Concurrent::FixedThreadPool.new(CONCURRENCY)

      manifest.each do |(mode, type, object_hash, path)|
        pool.post do
          target_path = File.join target_dir, path

          if mode == Envirobly::Git::Commit::SYMLINK_FILE_MODE
            fetch_symlink(object_hash, target_path:)
          else
            fetch_object(object_hash, target_path:)

            if mode == Envirobly::Git::Commit::EXECUTABLE_FILE_MODE
              FileUtils.chmod("+x", target_path)
            end
          end
        end
      end

      pool.shutdown
      pool.wait_for_termination
    end

    puts "Done in #{format_duration timings.real}"
  end

  private
    def list_object_hashes
      @client.list_objects({
        bucket: @bucket,
        prefix: "#{OBJECTS_PREFIX}/"
      }).map do |response|
        response.contents.map do |object|
          object.key.delete_prefix("#{OBJECTS_PREFIX}/").delete_suffix(".gz")
        end
      end.flatten
    end

    def object_key(object_hash)
      "#{OBJECTS_PREFIX}/#{object_hash}.gz"
    end

    def manifest_key(commit_ref)
      "#{MANIFESTS_PREFIX}/#{commit_ref}.gz"
    end

    def object_exists?(key)
      @client.head_object(bucket: @bucket, key:)
      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    def compress_and_upload_object(object_hash, chdir:)
      key = object_key object_hash

      Tempfile.create([ "envirobly-push", ".gz" ]) do |tempfile|
        gz = Zlib::GzipWriter.new(tempfile)

        Open3.popen3("git", "cat-file", "-p", object_hash, chdir:) do |_, stdout, stderr, thread|
          IO.copy_stream(stdout, gz)

          unless thread.value.success?
            raise "`git cat-file -p #{object_hash}` failed: #{stderr.read}"
          end
        ensure
          gz.close
        end

        @client.put_object(bucket: @bucket, body: tempfile, key:)

        puts "⤴ #{key}"
      end
    end

    def upload_git_objects(objects)
      pool = Concurrent::FixedThreadPool.new(CONCURRENCY)

      objects.each do |(chdir, object_hash)|
        pool.post do
          compress_and_upload_object(object_hash, chdir:)
        end
      end

      pool.shutdown
      pool.wait_for_termination
    end

    def upload_manifest(key, content)
      Tempfile.create([ "envirobly-push", ".gz" ]) do |tempfile|
        gz = Zlib::GzipWriter.new(tempfile)
        gz.write JSON.dump(content)
        gz.close

        @client.put_object(bucket: @bucket, body: tempfile, key:)

        puts "⤴ #{key}"
      end
    end

    def fetch_manifest(ref)
      stream = @bucket_resource.object(manifest_key(ref)).get.body
      JSON.parse Zlib::GzipReader.new(stream).read
    rescue Aws::S3::Errors::NoSuchKey
      puts "Commit #{ref} doesn't exist at s3://#{@bucket}"
      exit 1
    end

    def fetch_object(object_hash, target_path:)
      FileUtils.mkdir_p File.dirname(target_path)

      key = object_key object_hash
      stream = @bucket_resource.object(key).get.body

      File.open(target_path, "wb") do |target|
        gz = Zlib::GzipReader.new(stream)
        IO.copy_stream(gz, target)
        gz.close
      end
    end

    def fetch_symlink(object_hash, target_path:)
      FileUtils.mkdir_p File.dirname(target_path)

      key = object_key object_hash
      gz = Zlib::GzipReader.new @bucket_resource.object(key).get.body
      symlink_to = gz.read
      gz.close

      FileUtils.ln_s symlink_to, target_path
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
