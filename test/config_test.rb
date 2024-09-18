require "test_helper"

class Envirobly::ConfigTest < ActiveSupport::TestCase
  test "parsing" do
    commit = Envirobly::Git::Commit.new("38541a424ac370a6cccb4a4131f1125a7535cb84", working_dir:)
    config = Envirobly::Config.new commit
    assert_equal simple_config_yml, config.raw
    expected_hash = {
      services: {
        db: {
          type: "postgres",
          instance_type: "t4g.small"
        },
        app: {
          dockerfile: "Dockerfile",
          image_tag: "645842777640896aa3d68f2573be5d33571b5001"
        }
      }
    }
    assert_equal expected_hash, config.to_h
  end

  def simple_config_yml
    <<~YAML
      services:
        db:
          type: postgres
          instance_type: t4g.small
        app:
          dockerfile: Dockerfile
    YAML
  end

  def kitchen_sink_config_yml
    <<~YAML
      services:
        pg:
          name: Elephant
          type: postgres
          engine_version: 16.0
          instance_type: t4g.nano
          disk_size: 25
        mysql:
          name: Sun ☀️
          type: mysql
          engine_version: 8.1
          instance_type: t4g.nano
          disk_size: 30
        app:
          name: SuperApp
          dockerfile: Dockerfile.production
          build_context: app
          env:
            RAILS_MASTER_KEY:
              file: config/master.key
            WEATHER: sunny
            RAILS_ENV: preview
            DATABASE_URL:
              service: pg
              key: url
          instance_type: t4g.small
          health_check_path: /up
        blog:
          image: wordpress
          env:
            DATABASE_HOST:
              service: mysql
              key: host
            DATABASE_NAME:
              service: mysql
              key: name
          volume_mount_path: /usr/public/html
          disk_size: 30

      environments:
        production:
          pg:
            instance_type: t4g.large
            disk_size: 400
          mysql:
            instance_type: t4g.2xlarge
            disk_size: 500
          app:
            name: SuperApp Production
            dockerfile: Dockerfile.production
            build_context: app
            env:
              RAILS_MASTER_KEY:
                WEATHER: null
                RAILS_ENV: production
                RAILS_MAX_THREADS: 5
            instance_type: t4g.medium
            min_instances: 2
            max_instances: 4
    YAML
  end
end
