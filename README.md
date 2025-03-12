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
gem install ./envirobly-$(ruby -Ilib/ bin/envirobly version).gem --no-document
gem push envirobly-$(ruby -Ilib/ bin/envirobly version).gem
```

## Docker build

```sh
docker build -t envirobly-cli .

# Testing the build with some commands:
docker run -it --rm envirobly-cli
docker run -it --rm -v $(pwd):/app:ro envirobly-cli envirobly validate
docker run -it --rm -v $(pwd):/app:ro -v ~/.aws:/root/.aws:ro envirobly-cli envirobly push <s3-bucket>
```

## Command examples

### Deploy

```sh
export ENVIROBLY_API_HOST=hostname # to override the default envirobly.com
envirobly deploy <env-logical-id-or-url>
```
