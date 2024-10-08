require "test_helper"

class Envirobly::ConfigTest < ActiveSupport::TestCase
  test "compile simple config" do
    commit = Envirobly::Git::Commit.new("38541a424ac370a6cccb4a4131f1125a7535cb84", working_dir:)
    config = Envirobly::Config.new commit
    assert_equal simple_config_yml, config.raw
    config.compile
    assert_equal simple_config, config.result
  end

  test "compile kitchen sink config" do
    commit = Envirobly::Git::Commit.new("ac3457fbdd2ef219a8e2e0e074365092970d5dd3", working_dir:)
    config = Envirobly::Config.new commit
    assert_equal kitchen_sink_config_yml, config.raw
    config.compile
    assert_equal kitchen_sink_config, config.result
  end

  test "compile for an arbitrary environment that is not specified in overrides" do
    commit = Envirobly::Git::Commit.new("ac3457fbdd2ef219a8e2e0e074365092970d5dd3", working_dir:)
    config = Envirobly::Config.new commit
    config.compile("staging")
    assert_equal kitchen_sink_config, config.result
  end

  test "compile kitchen sink config for environment with overrides" do
    commit = Envirobly::Git::Commit.new("ac3457fbdd2ef219a8e2e0e074365092970d5dd3", working_dir:)
    config = Envirobly::Config.new commit
    config.compile("production")
    # puts config.errors
    assert_equal kitchen_sink_production_config, config.result
  end

  test "to_deployment_params" do
    commit = Minitest::Mock.new
    def commit.file_content(_)
      <<~YAML
        project: https://envirobly.com/projects/1
        services:
          blog:
            image: wordpress
      YAML
    end
    def commit.ref
      "ac3457fbdd2ef219a8e2e0e074365092970d5dd3"
    end
    def commit.time
      Time.local(2024, 1, 1)
    end
    def commit.message
      "hello"
    end
    def commit.objects_with_checksum_at(_)
      []
    end
    config = Envirobly::Config.new commit
    config.compile("staging")
    expected = {
      environ: {
        name: "staging",
        project_url: "https://envirobly.com/projects/1"
      },
      commit: {
        ref: "ac3457fbdd2ef219a8e2e0e074365092970d5dd3",
        time: Time.local(2024, 1, 1),
        message: "hello"
      },
      config: {
        services: {
          blog: {
            image: "wordpress"
          }
        }
      },
      raw_config: <<~YAML
        project: https://envirobly.com/projects/1
        services:
          blog:
            image: wordpress
      YAML
    }
    assert_equal expected, config.to_deployment_params
  end

  test "validate: YAML parsing error" do
    commit = Minitest::Mock.new
    def commit.file_content(_)
      <<~YAML
        invalid_yaml:
        [
      YAML
    end
    config = Envirobly::Config.new commit
    config.validate
    assert_equal 1, config.errors.size
    assert_equal "(<unknown>): could not find expected ':' while scanning a simple key at line 2 column 1", config.errors.first
  end

  test "validate: dockerfile and build_context specified don't exist in this commit" do
    commit = Minitest::Mock.new
    def commit.file_content(_)
      <<~YAML
        project: https://envirobly.test/1/projects/4
        services:
          hi:
            dockerfile: nope
            build_context: neither
      YAML
    end
    def commit.file_exists?(_)
      false
    end
    def commit.dir_exists?(_)
      false
    end
    config = Envirobly::Config.new commit
    config.validate
    assert_equal 2, config.errors.size
    assert_equal "Service `hi` specifies `dockerfile` as `nope` which doesn't exist in this commit.", config.errors.first
    assert_equal "Service `hi` specifies `build_context` as `neither` which doesn't exist in this commit.", config.errors.second
  end

  test "validate: no project url" do
    commit = Minitest::Mock.new
    def commit.file_content(_)
      <<~YAML
        services:
          blog/.-_:
            image: wordpress
      YAML
    end
    def commit.objects_with_checksum_at(_)
      []
    end
    def commit.file_exists?(_)
      true
    end
    def commit.dir_exists?(_)
      true
    end
    config = Envirobly::Config.new commit
    config.validate
    assert_equal 1, config.errors.size
    assert_equal "Missing `project: <url>` top level attribute.", config.errors.first
  end

  test "validate: invalid service and environment names" do
    commit = Minitest::Mock.new
    def commit.file_content(_)
      <<~YAML
        project: https://envirobly.test/1/projects/4
        services:
          blóg:
            image: wordpress
        environments:
          stáging: {}
      YAML
    end
    def commit.objects_with_checksum_at(_)
      []
    end
    def commit.file_exists?(_)
      true
    end
    def commit.dir_exists?(_)
      true
    end
    config = Envirobly::Config.new commit
    config.validate
    assert_equal 2, config.errors.size
    assert_match /`blóg` is not a valid service name/, config.errors.first
    assert_match /`stáging` is not a valid environment name/, config.errors.second
  end

  test "validate: env var hash has unknown attributes" do
    skip "TODO"
  end

  test "validate: unknown top level key used" do
    skip "TODO"
  end

  test "validate: unknown service level key used" do
    skip "TODO"
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
          dockerfile: "Dockerfile"
        }
      }
    }
  end

  def kitchen_sink_config_yml
    <<~YAML
      services:
        pg:
          type: postgres
          engine_version: 16.0
          instance_type: t4g.nano
          volume_size: 25
        mysql:
          type: mysql
          engine_version: 8.1
          instance_type: t4g.nano
          volume_size: 30
        app:
          dockerfile: Dockerfile.production
          build_context: app
          command: rails s
          env:
            RAILS_MASTER_KEY:
              secret: master-key
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
            dockerfile: Dockerfile.production
            build_context: app
            env:
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
          type: "postgres",
          engine_version: 16.0,
          instance_type: "t4g.nano",
          volume_size: 25
        },
        mysql: {
          type: "mysql",
          engine_version: 8.1,
          instance_type: "t4g.nano",
          volume_size: 30
        },
        app: {
          dockerfile: "Dockerfile.production",
          build_context: "app",
          command: "rails s",
          env: {
            RAILS_MASTER_KEY: {
              secret: "master-key"
            },
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
          type: "postgres",
          engine_version: 16.0,
          instance_type: "t4g.large",
          volume_size: 400
        },
        mysql: {
          type: "mysql",
          engine_version: 8.1,
          instance_type: "t4g.2xlarge",
          volume_size: 500
        },
        app: {
          dockerfile: "Dockerfile.production",
          build_context: "app",
          command: "rails s",
          env: {
            RAILS_MASTER_KEY: {
              secret: "master-key"
            },
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
