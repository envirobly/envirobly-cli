# Envirobly CLI 🚀

Deploy to [Envirobly](https://envirobly.com/) from your terminal.

## ⚡️ Quick start
- Install Ruby >= 3.2.
- `gem install envirobly`
- `envirobly signin` (paste an access token from https://on.envirobly.com/profile/access_tokens)
- `envirobly validate` (check your config)
- `envirobly deploy` (deploys the current commit to an environ named after your git branch)

## 🔑 Auth: signin / signout
- `envirobly signin` prompts for an access token, validates it, and stores it as `~/.local/share/envirobly/access_token`.
- `envirobly signout` deletes the stored token. You can always supply `ENVIROBLY_ACCESS_TOKEN` instead of storing it.

## 🗂 Project config
- Config lives in `.envirobly/deploy.yml`; per-environ overrides go in `.envirobly/deploy.<environ>.yml`.
- Files are YAML with ERB interpolation; `!secret` tags keep sensitive values opaque in output.
- Example:
  ```yaml
  # .envirobly/deploy.yml
  services:
    web:
      image: my/web:latest
      env:
        DATABASE_URL: !secret <%= ENV["DATABASE_URL"] %>
  ```
- Validate your config: `envirobly validate` or `envirobly validate staging` (merges `.envirobly/deploy.staging.yml` first).

## 🎯 Targets & defaults
- Targets capture your account URL, project name, and region and are stored in `.envirobly/.targets/<name>/`.
- `envirobly target` guides you through selecting account, project, and region, then saves them as the `.default` target.
- Provide a name to maintain multiple defaults: `envirobly target my-app/` (note the trailing slash).
- Environ names accept letters, numbers, dashes, and underscores.

## 🚀 Deploy
- Command: `envirobly deploy [[TARGET/][ENVIRON_NAME]]`
- Defaults:
  - Target: `.default`
  - Environ: current git branch
  - Commit: `HEAD`
- Helpful flags: `--account-url=... --region=... --project-name=... --commit=<ref> --dry-run`
- Safety: refuses unknown commit refs; warns if you have uncommitted changes (they are not deployed).
- Examples:
  - `envirobly deploy` → deploy current branch to the default target.
  - `envirobly deploy staging` → deploy to environ `staging` using the default target.
  - `envirobly deploy my-app/` → use target `my-app`, environ defaults to branch name.
  - `envirobly deploy my-app/prod` → target `my-app`, environ `prod`.
  - `envirobly deploy --dry-run` → show config/target details without uploading or deploying.

## 📊 Instance types
- `envirobly instance_types [REGION]` prints a table of available instance types, vCPU, memory, price, and group.
- If region is omitted, the CLI uses your saved target region or prompts you to pick one.

## 🐚 Service shells & file sync
- `envirobly exec SERVICE [COMMAND...]`
  - With no command, opens an interactive shell in the service container.
  - With a command, runs it once: `envirobly exec web rails db:migrate`.
  - Paths accept `SERVICE`, `ENVIRON/SERVICE`, or `TARGET/ENVIRON/SERVICE`.
  - Options: `--instance-slot=<n>` (choose instance), `--shell=/bin/sh`, `--user=root`, `--dry-run` (print connection payload).
- `envirobly rsync [SERVICE:]SOURCE [SERVICE:]DEST`
  - Sync local files ↔ service data volume via `rsync`.
  - Defaults to `-avzP`; override with `--args="-av --delete"`.
  - Same path forms as `exec`, e.g. `envirobly rsync web:logs/ ./logs/`.

## 📥 Build context (builders)
- `envirobly pull REGION BUCKET REF PATH` downloads a build context from S3. Used by Envirobly builders; not for normal CLI use.

## 🧰 Other utilities
- `envirobly version` or `envirobly version --pure` (just the number) for scripting.

## 🐳 Docker usage
- Build the image: `docker build -t envirobly-cli .`
- Check it works: `docker run -it --rm envirobly-cli envirobly version`
- Validate config from your project dir (read-only mount):  
  `docker run -it --rm -v $(pwd):/app:ro envirobly-cli envirobly validate`
- Deploy/pull using your AWS creds (mounted read-only):  
  `docker run -it --rm -v $(pwd):/app:ro -v ~/.aws:/root/.aws:ro envirobly-cli envirobly pull <region> <bucket> <ref> <path>`

## 🧑‍💻 Development
- Run locally from the repo: `ruby -Ilib/ bin/envirobly version`
- Create a handy alias:  
  `alias envirobly-dev="ruby -I$HOME/envirobly/envirobly-cli/lib/ $HOME/envirobly/envirobly-cli/bin/envirobly"`

## 🆘 Need help?
- Run with `ENVIROBLY_CLI_LOG_LEVEL=debug` to inspect API traffic.
- If a command fails with 401, re-run `envirobly signin` or set `ENVIROBLY_ACCESS_TOKEN`.
