# envirobly-cli

## Development

```sh
ruby -Ilib/ bin/envirobly version
```

## Releasing

```sh
gem build envirobly.gemspec
gem install ./envirobly-0.1.0.gem --no-document
gem push envirobly-0.1.0.gem
```

## Command examples

### Deploy

```sh
export ENVIROBLY_API_HOST=hostname # to override the default envirobly.com
envirobly deploy production --bucket s3-bucket-name
```
