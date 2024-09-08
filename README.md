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

## Command examples

### Deploy

```sh
export ENVIROBLY_API_HOST=hostname # to override the default envirobly.com
envirobly deploy <env-logical-id-or-url>
```
