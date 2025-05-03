# envirobly-cli

## Development

### Running from within the working dir

```sh
ruby -Ilib/ bin/envirobly version
```

### Creating global alias to the dev executable

```sh
alias envirobly="ruby -I$HOME/envirobly/envirobly-cli/lib/ $HOME/envirobly/envirobly-cli/bin/envirobly"
```

## Releasing

```sh
gem build envirobly.gemspec
gem install ./envirobly-$(ruby -Ilib/ bin/envirobly version --pure).gem --no-document
gem push envirobly-$(ruby -Ilib/ bin/envirobly version --pure).gem
```

## Docker build

```sh
docker build -t envirobly-cli .

# Testing the build with some commands:
docker run -it --rm envirobly-cli
```

## Command examples

### Deploy

```sh
export ENVIROBLY_API_HOST=hostname # to override the default envirobly.com
envirobly deploy <env-logical-id-or-url>
```

### With Docker

```sh
docker run -it --rm -v $(pwd):/app:ro envirobly-cli envirobly validate
docker run -it --rm -v $(pwd):/app:ro -v ~/.aws:/root/.aws:ro envirobly-cli envirobly push <s3-region> <s3-bucket>
```

## Ways to deploy

```sh
# Deploy to default account and project and environment named after the current branch.
# If default project is not set (.envirobly/projects/default.yml), ask to
# fill in project name (defaults to current directory name) and region.
# If user has access to multiple accounts, ask which account to use.
envirobly deploy

# Deploy to environment named as the first argument, to the default project.
envirobly deploy staging

# Deploy to a different project and a named environment. If project is not configured,
# asks for region to deploy to.
envirobly deploy beta/staging

# Questions can be skipped by specifying answers as arguments.
envirobly deploy --account=1 --project=foo --region=eu-north-1

# Use defaults (us-east-1, dir and branch names) and don't ask any questions (for CIs).
envirobly deploy --unattended
```
