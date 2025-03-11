require "zlib"
require "open3"
require "benchmark"
require "concurrent"
require "aws-sdk-s3"

class Envirobly::Aws::S3
  OBJECTS_PREFIX = "blobs"
  MANIFESTS_PREFIX = "manifests"
  UPLOAD_CONCURRENCY = 6

  def initialize(bucket)
    @bucket = bucket
    @client = Aws::S3::Client.new # TODO: region and creds should be passed
  end

  def push(commit)
    puts "Pushing commit #{commit.ref} to #{@bucket}"

    # TODO: If remote manifest already exists, exit

    remote_object_hashes = list_object_hashes
    # TODO: Distinguish between blob/symlink/commit types (if necessary)
    # TODO: Object tree map should do recursion for submodules (probably)
    local_object_hashes = commit.object_tree.map { |object| object[:hash] }
    object_hashes_to_upload = local_object_hashes - remote_object_hashes

    timings = Benchmark.measure do
      puts "Uploading #{object_hashes_to_upload.size} out of #{local_object_hashes.size}"
      upload_git_objects object_hashes_to_upload

      # TODO: Push commit manifest
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

    def object_hash_to_key(object_hash)
      "#{OBJECTS_PREFIX}/#{object_hash}.gz"
    end

    def object_exists?(key)
      @client.head_object(bucket: @bucket, key:)
      true
    rescue Aws::S3::Errors::NotFound
      false
    end

    def compress_and_upload_object(object_hash)
      key = object_hash_to_key object_hash

      Tempfile.create(["envirobly-push", ".gz"]) do |tempfile|
        Zlib::GzipWriter.new(tempfile) do |gz|
          Open3.popen3("git", "cat-file", "-p", object_hash) do |_, stdout, stderr, thread|
            IO.copy_stream(stdout, gz)

            unless thread.value.success?
              raise "`git cat-file -p #{object_hash}` failed: #{stderr.read}"
            end
          end
        end

        @client.put_object(bucket: @bucket, body: tempfile, key:)

        puts "⤴ #{key}"
      end
    end

    def upload_git_objects(object_hashes)
      pool = Concurrent::FixedThreadPool.new(UPLOAD_CONCURRENCY)

      object_hashes.each do |object_hash|
        pool.post do
          compress_and_upload_object object_hash
        end
      end

      pool.shutdown
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
