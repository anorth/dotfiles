#!/usr/bin/env bash
# Link this repo's contents into the current machine's home directory.
# Safe to re-run: existing correct links are left alone, and anything that is
# not a symlink is reported and skipped rather than overwritten.
set -euo pipefail

DOTFILES=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Files to link, as "path in this repo:path under $HOME".
LINKS=(
  "bin/replace-all:bin/replace-all"
  "git/gitconfig:.gitconfig"
  "git/ignore:.config/git/ignore"
)

# Skills are read from here by Cursor directly, and the location is neutral
# across agents.
SKILL_DIR=$HOME/.agents/skills

dry_run=0

usage() {
  cat <<'EOF'
Usage: install.sh [-n|--dry-run]

  -n, --dry-run   Print what would change without touching the filesystem.
EOF
}

while (($#)); do
  case $1 in
    -n | --dry-run) dry_run=1 ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

verb=linked
if ((dry_run)); then verb="would link"; fi

act() {
  ((dry_run)) || "$@"
}

# link <target> <link path>
link() {
  local target=$1 path=$2
  if [[ -L $path ]]; then
    [[ $(readlink "$path") == "$target" ]] && return 0
  elif [[ -e $path ]]; then
    echo "kept $path: already exists and is not a symlink, so leaving it alone"
    return 0
  fi
  act mkdir -p -- "$(dirname -- "$path")"
  act ln -sfn -- "$target" "$path"
  echo "$verb $path -> $target"
}

for entry in "${LINKS[@]}"; do
  link "$DOTFILES/${entry%%:*}" "$HOME/${entry#*:}"
done

for source in "$DOTFILES"/skills/*/; do
  [[ -d $source ]] || continue
  name=$(basename -- "$source")
  link "$DOTFILES/skills/$name" "$SKILL_DIR/$name"
done
