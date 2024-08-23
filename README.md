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
gem install ./envirobly-0.1.0.gem --no-document
gem push envirobly-0.1.0.gem
```

## Command examples

### Deploy

```sh
export ENVIROBLY_API_HOST=hostname # to override the default envirobly.com
envirobly deploy <env-logical-id-or-url>
```
