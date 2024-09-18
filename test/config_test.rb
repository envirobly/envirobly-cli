require "test_helper"

class Envirobly::ConfigTest < ActiveSupport::TestCase
  def test_parsing
    commit = Envirobly::Git::Commit.new("38541a424ac370a6cccb4a4131f1125a7535cb84", working_dir:)
    config = Envirobly::Config.new commit
    assert_equal config_yml, config.raw
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

  private
    def config_yml
      <<~YAML
        services:
          db:
            type: postgres
            instance_type: t4g.small
          app:
            dockerfile: Dockerfile
      YAML
    end
end
