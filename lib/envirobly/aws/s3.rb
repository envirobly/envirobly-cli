class Envirobly::Aws::S3
  def initialize(bucket)
    @bucket = bucket
  end

  def push(commit)
    puts "Pushing #{commit.ref} to #{@bucket}"
    puts commit.object_tree
  end
end
