#!/usr/bin/env bash

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
	cat <<'EOF'
Usage: ./symlink.sh [options]

Options:
  --host NAME         Use the specified host profile instead of auto-detecting.
  --remember-host     Persist the chosen host to ~/.dotfiles-host for future runs.
  --ensure-local      Create the hosts-local/<NAME> directory for quick overrides.
  --local-root PATH   Store local overrides under PATH instead of the default hosts-local/.
  -h, --help          Show this help message and exit.

Environment variables:
  DOTFILES_HOST              Override host detection (same as --host).
  DOTFILES_HOSTS_LOCAL_DIR   Override the default hosts-local/ directory.
EOF
}

die() {
	printf 'Error: %s\n' "$*" >&2
	printf '\n' >&2
	usage >&2
	exit 1
}

HOST_OVERRIDE=""
REMEMBER_HOST=0
ENSURE_LOCAL=0
CUSTOM_LOCAL_ROOT=""

while [[ $# -gt 0 ]]; do
	case "$1" in
		--host)
			shift || die "--host requires an argument"
			HOST_OVERRIDE="$1"
			;;
		--remember-host)
			REMEMBER_HOST=1
			;;
		--ensure-local)
			ENSURE_LOCAL=1
			;;
		--local-root)
			shift || die "--local-root requires a path"
			CUSTOM_LOCAL_ROOT="$1"
			;;
		-h|--help)
			usage
			exit 0
			;;
		*)
			die "Unknown option: $1"
			;;
	esac
	shift || break
done

DOTFILES_HOST="${DOTFILES_HOST:-}"
HOSTS_LOCAL_ROOT="${DOTFILES_HOSTS_LOCAL_DIR:-$CURRENT_DIR/hosts-local}"

if [[ -n "$CUSTOM_LOCAL_ROOT" ]]; then
	HOSTS_LOCAL_ROOT="$CUSTOM_LOCAL_ROOT"
fi

if [[ -z "$DOTFILES_HOST" ]] && [[ -f "$HOME/.dotfiles-host" ]]; then
	read -r DOTFILES_HOST < "$HOME/.dotfiles-host"
	DOTFILES_HOST="${DOTFILES_HOST%%[[:space:]]*}"
fi

if [[ -z "$DOTFILES_HOST" ]]; then
	if [[ -n "${HOSTNAME:-}" ]]; then
		DOTFILES_HOST="$HOSTNAME"
	elif command -v hostname >/dev/null 2>&1; then
		DOTFILES_HOST="$(hostname -s 2>/dev/null || hostname)"
	else
		DOTFILES_HOST="unknown-host"
	fi
fi

DOTFILES_HOST="${DOTFILES_HOST// /}"

if [[ -n "$HOST_OVERRIDE" ]]; then
	DOTFILES_HOST="${HOST_OVERRIDE// /}"
fi

if [[ -z "$DOTFILES_HOST" ]]; then
	die "Could not determine a host profile. Pass --host NAME explicitly."
fi

printf 'Linking dotfiles for host: %s\n' "$DOTFILES_HOST"
printf 'Local overrides directory: %s\n' "$HOSTS_LOCAL_ROOT/$DOTFILES_HOST"

if (( ENSURE_LOCAL )); then
	mkdir -p "$HOSTS_LOCAL_ROOT/$DOTFILES_HOST"
fi

if (( REMEMBER_HOST )); then
	printf '%s\n' "$DOTFILES_HOST" > "$HOME/.dotfiles-host"
	printf 'Saved host to %s\n' "$HOME/.dotfiles-host"
fi

# Same as ln -sb (backup if file exists)
# but mac compatible
# note that the second argument must be a directory.
ln_sb() {
	file_relpath="$1"
	dest_dir="$2"

	basename="$(basename "$file_relpath")"
	dest_file="$dest_dir/$basename"

	mkdir -p "$dest_dir"
	if [[ -f "$dest_file" ]] || [[ -d "$dest_file" ]]; then
		echo "Backing up $dest_file to ${dest_file}~"
		if [[ -f "$dest_file"~ ]] || [[ -d "$dest_file"~ ]]; then
			\rm -rf "${dest_file}"~
		fi
		mv "$dest_file" "${dest_file}"~
	fi

	local source_path="$file_relpath"
	if [[ "$file_relpath" != /* ]]; then
		source_path="$CURRENT_DIR/$file_relpath"
	fi

	ln -s "$source_path" "$dest_dir"
}

ln_host_aware() {
	local base_relpath="$1"
	local dest_dir="$2"
	local local_override="$HOSTS_LOCAL_ROOT/$DOTFILES_HOST/$base_relpath"
	local host_relpath="hosts/${DOTFILES_HOST}/$base_relpath"
	local source_relpath="$base_relpath"

	if [[ -e "$local_override" ]]; then
		local display_path="${local_override#$CURRENT_DIR/}"
		if [[ "$display_path" == "$local_override" ]]; then
			display_path="$local_override"
		fi
		printf 'Using host-specific override (local): %s\n' "$display_path"
		ln_sb "$local_override" "$dest_dir"
		return
	fi

	if [[ -e "$CURRENT_DIR/$host_relpath" ]]; then
		printf 'Using host-specific override: %s\n' "$host_relpath"
		source_relpath="$host_relpath"
	fi

	ln_sb "$source_relpath" "$dest_dir"
}

ln_host_aware nvim ~/.config
ln_host_aware oh-my-zsh/.zshrc ~
ln_host_aware i3 ~/.config
ln_host_aware alacritty ~/.config
ln_host_aware tmux/.tmux.conf ~/
ln_host_aware nitrogen ~/.config
ln_host_aware redshift ~/.config
ln_host_aware rofi ~/.config
ln_host_aware bat ~/.config
