# envirobly-cli

## Development

### Running from within the working dir

```sh
ruby -Ilib/ bin/envirobly version
```

### Creating global alias to the dev executable

```sh
alias envirobly-dev="ruby -I$HOME/envirobly/envirobly-cli/lib/ $HOME/envirobly/envirobly-cli/bin/envirobly"
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
docker run -it --rm envirobly-cli envirobly version
```

### With Docker

```sh
docker run -it --rm -v $(pwd):/app:ro envirobly-cli envirobly validate
docker run -it --rm -v $(pwd):/app:ro -v ~/.aws:/root/.aws:ro envirobly-cli envirobly push <s3-region> <s3-bucket>
```

## Ways to deploy

```sh
# Deploy using saved defaults. If defaults are missing, it will ask you
# where you want to deploy and save the answers as project defaults. These
# can then be committed into your repository.
envirobly deploy

# Deploy to an environ named "staging"
envirobly deploy staging

# Specify project name, where otherwise directory name would be used
envirobly deploy --project-name=custom

# Specify project ID directly
envirobly deploy --project-id=123

# Questions can be skipped by specifying answers as arguments.
envirobly deploy --account-id=1 --region=eu-north-1
```
