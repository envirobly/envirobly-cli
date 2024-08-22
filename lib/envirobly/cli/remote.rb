class Envirobly::Cli::Remote < Envirobly::Base
  URL_MATCHER = /^https:\/\/envirobly\.test\/(\d+)\/projects\/(\d+)$/

  desc "add NAME URL", "Add a remote (connect a project by URL)"
  def add(name, url)
    unless url =~ URL_MATCHER
      $stderr.puts "URL must match https://envirobly.com/[number]/projects/[number]"
      exit 1
    end

    puts "TODO add remote #{name} #{url}"
  end

  desc "show", "Show connected projects"
  def show
    puts "TODO list remotes"
  end
end
