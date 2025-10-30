# Host-specific dotfiles

Create host-specific overrides under `hosts/<profile>` (checked into git) or `hosts-local/<profile>` (ignored from git) when you need a machine to differ from the shared defaults.

## Selecting the profile

The symlinking script determines which profile to use in this order:

1. `DOTFILES_HOST` environment variable when invoking `symlink.sh`
2. The contents of `~/.dotfiles-host` on the current machine (first word of the file)
3. The `HOSTNAME` environment variable
4. `hostname -s` (or `hostname` as a last resort)

For example, to identify this computer as `work-pc` persistently, place the text `work-pc` in `~/.dotfiles-host`.

## Adding overrides

Mirror the existing directory structure underneath your host profile. When `symlink.sh` runs, it searches for overrides in this order:

1. `hosts-local/<profile>/…` (ignored by git so you can keep work-specific or secret tweaks locally)
2. `hosts/<profile>/…` (checked-in overrides shared across machines that use the same profile)
3. The top-level default files

Examples:

- `hosts-local/work-pc/oh-my-zsh/.zshrc` (private to this computer)
- `hosts/home-pc/nvim/init.lua` (shared with any machine that uses `home-pc`)

Only the files and directories you create inside the profile override the shared defaults; everything else keeps using the top-level versions.

## Quick start on a new machine

```sh
./symlink.sh --host work-pc --remember-host --ensure-local
```

That one-liner:

- forces the profile to `work-pc` (instead of relying on hostname heuristics),
- writes `work-pc` to `~/.dotfiles-host` for future runs,
- ensures `hosts-local/work-pc/` exists so you can drop local-only overrides right away.

From then on, just edit files under `hosts-local/work-pc/` to keep differences off the public repo, and rerun `./symlink.sh` whenever you add new files.

## Command-line options

Run `./symlink.sh --help` to see every flag. The most useful ones:

- `--host NAME` – explicit profile selection (same as setting `DOTFILES_HOST`)
- `--remember-host` – writes the name into `~/.dotfiles-host`
- `--ensure-local` – creates `hosts-local/<NAME>/` if it is missing
- `--local-root PATH` – store local overrides somewhere outside the repo
