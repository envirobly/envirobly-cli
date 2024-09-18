require "test_helper"

class Envirobly::ConfigTest < ActiveSupport::TestCase
  test "compile simple config" do
    commit = Envirobly::Git::Commit.new("38541a424ac370a6cccb4a4131f1125a7535cb84", working_dir:)
    config = Envirobly::Config.new commit
    assert_equal simple_config_yml, config.raw
    assert_equal simple_config, config.compile
  end

  test "compile kitchen sink config" do
    commit = Envirobly::Git::Commit.new("210f84ac05698bbb494ff329e84910f5981fdd86", working_dir:)
    config = Envirobly::Config.new commit
    assert_equal kitchen_sink_config_yml, config.raw
    assert_equal kitchen_sink_config, config.compile
    assert_equal kitchen_sink_config, config.compile("staging"), "Compiling for an arbitrary environment that is not specified in overrides"
  end

  test "compile kitchen sink config for environment with overrides" do
    commit = Envirobly::Git::Commit.new("210f84ac05698bbb494ff329e84910f5981fdd86", working_dir:)
    config = Envirobly::Config.new commit
    assert_equal kitchen_sink_production_config, config.compile("production")
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

  def simple_config
    {
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
  end

  def kitchen_sink_config_yml
    <<~YAML
      services:
        pg:
          name: Elephant
          type: postgres
          engine_version: 16.0
          instance_type: t4g.nano
          volume_size: 25
        mysql:
          name: Sun ☀️
          type: mysql
          engine_version: 8.1
          instance_type: t4g.nano
          volume_size: 30
        app:
          name: SuperApp
          dockerfile: Dockerfile.production
          build_context: app
          command: rails s
          env:
            RAILS_MASTER_KEY:
              file: config/master.key
            WEATHER: sunny
            RAILS_ENV: preview
            DATABASE_URL:
              service: pg
              key: url
          instance_type: t4g.small
          health_check: /up
        blog:
          image: wordpress
          env:
            DATABASE_HOST:
              service: mysql
              key: host
            DATABASE_NAME:
              service: mysql
              key: name
          volume_mount: /usr/public/html
          volume_size: 30
          private: true

      environments:
        production:
          pg:
            instance_type: t4g.large
            volume_size: 400
          mysql:
            instance_type: t4g.2xlarge
            volume_size: 500
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

  def kitchen_sink_config
    {
      services: {
        pg: {
          name: "Elephant",
          type: "postgres",
          engine_version: 16.0,
          instance_type: "t4g.nano",
          volume_size: 25
        },
        mysql: {
          name: "Sun ☀️",
          type: "mysql",
          engine_version: 8.1,
          instance_type: "t4g.nano",
          volume_size: 30
        },
        app: {
          name: "SuperApp",
          dockerfile: "Dockerfile.production",
          build_context: "app",
          command: "rails s",
          env: {
            RAILS_MASTER_KEY: "MKEY",
            WEATHER: "sunny",
            RAILS_ENV: "preview",
            DATABASE_URL: {
              service: "pg",
              key: "url"
            }
          },
          instance_type: "t4g.small",
          health_check: "/up",
          image_tag: "202ee5bc619132740ead9058ac2b702d08407d3b"
        },
        blog: {
          image: "wordpress",
          env: {
            DATABASE_HOST: {
              service: "mysql",
              key: "host"
            },
            DATABASE_NAME: {
              service: "mysql",
              key: "name"
            }
          },
          volume_mount: "/usr/public/html",
          volume_size: 30,
          private: true
        }
      }
    }
  end

  def kitchen_sink_production_config
    {
      services: {
        pg: {
          name: "Elephant",
          type: "postgres",
          engine_version: 16.0,
          instance_type: "t4g.large",
          volume_size: 400
        },
        mysql: {
          name: "Sun ☀️",
          type: "mysql",
          engine_version: 8.1,
          instance_type: "t4g.2xlarge",
          volume_size: 500
        },
        app: {
          name: "SuperApp Production",
          dockerfile: "Dockerfile.production",
          build_context: "app",
          command: "rails s",
          env: {
            RAILS_MASTER_KEY: "MKEY",
            RAILS_ENV: "production",
            DATABASE_URL: {
              service: "pg",
              key: "url"
            },
            RAILS_MAX_THREADS: 5
          },
          instance_type: "t4g.medium",
          min_instances: 2,
          max_instances: 4,
          health_check: "/up",
          image_tag: "202ee5bc619132740ead9058ac2b702d08407d3b"
        },
        blog: {
          image: "wordpress",
          env: {
            DATABASE_HOST: {
              service: "mysql",
              key: "host"
            },
            DATABASE_NAME: {
              service: "mysql",
              key: "name"
            }
          },
          volume_mount: "/usr/public/html",
          volume_size: 30,
          private: true
        }
      }
    }
  end
end
