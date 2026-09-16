#!/usr/bin/env bash
# Link this repo's contents into the current machine's home directory.
# Safe to re-run: existing correct links are left alone, and anything that is
# not a symlink is reported and skipped rather than overwritten.
set -euo pipefail

DOTFILES=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Skills are collected under one agent-neutral hub, then each agent's own skills
# directory links to the hub. Skills installed by other tools can live in the hub
# alongside these and get picked up by the same fan-out.
SKILL_HUB=$HOME/.agents/skills
AGENT_SKILL_DIRS=("$HOME/.cursor/skills" "$HOME/.claude/skills")

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
    echo "skipped $path: exists and is not a symlink; move it aside to adopt it"
    return 0
  fi
  act mkdir -p -- "$(dirname -- "$path")"
  act ln -sfn -- "$target" "$path"
  echo "$verb $path -> $target"
}

# Every skill this repo owns, plus any already in the hub from other tools, so
# that a skill installed by e.g. a skills CLI fans out to each agent as well.
skill_names=()
seen=" "
collect() {
  local dir name
  for dir in "$1"/*/; do
    [[ -d $dir ]] || continue
    name=$(basename -- "$dir")
    case $seen in *" $name "*) continue ;; esac
    seen="$seen$name "
    skill_names+=("$name")
  done
}
collect "$DOTFILES/skills"
collect "$SKILL_HUB"

for name in "${skill_names[@]}"; do
  if [[ -d $DOTFILES/skills/$name ]]; then
    link "$DOTFILES/skills/$name" "$SKILL_HUB/$name"
  fi
  for agent_dir in "${AGENT_SKILL_DIRS[@]}"; do
    link "$SKILL_HUB/$name" "$agent_dir/$name"
  done
done
