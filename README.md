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
