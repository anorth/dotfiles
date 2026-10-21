#!/usr/bin/env bash
# Link this repo's contents into the current machine's home directory.
# Safe to re-run: existing correct links are left alone, and anything that is
# not a symlink is reported and skipped rather than overwritten.
set -euo pipefail

DOTFILES=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Files to link, as "path in this repo:path under $HOME".
LINKS=(
  "bin/gflow:.local/bin/gflow"
  "bin/replace-all:.local/bin/replace-all"
  "git/gitconfig:.gitconfig"
  "git/ignore:.config/git/ignore"
  "shell/common.sh:.config/shell/common.sh"
  "shell/zshrc:.zshrc"
)

# External checkouts, as "dest|sibling|url".
# dest is relative to $HOME. sibling is a directory name next to this repo, or
# "-" when the home path is the only location. A sibling checkout is used as-is
# (the copy you edit). Otherwise dest is cloned or fast-forwarded. Dirty,
# diverged, or unreachable trees are reported and skipped.
REPOS=(
  "agent-skills|agent-skills|https://github.com/anorth/agent-skills.git"
  ".oh-my-zsh|-|https://github.com/ohmyzsh/ohmyzsh.git"
)

# Skills are linked into each dest so Cursor (~/.agents) and Claude Code
# (~/.claude) both see them.
SKILL_DIRS=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
)

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

# Resolve or refresh one entry from REPOS. Sets resolved_repo to the checkout
# to use, or empty when that entry was skipped. Never fails the installer.
ensure_repo() {
  local dest_rel=$1 sibling_name=$2 url=$3
  local parent sibling dest
  parent=$(dirname -- "$DOTFILES")
  dest=$HOME/$dest_rel
  resolved_repo=

  if [[ $sibling_name != - ]]; then
    sibling=$parent/$sibling_name
    if [[ -d $sibling/.git ]]; then
      resolved_repo=$sibling
      echo "using $resolved_repo"
      return 0
    fi
  fi

  if [[ -d $dest/.git ]]; then
    resolved_repo=$dest
    if ((dry_run)); then
      echo "would update $dest"
      return 0
    fi
    if [[ -n $(git -C "$dest" status --porcelain 2>/dev/null) ]]; then
      echo "kept $dest: working tree is dirty, skipping pull"
      return 0
    fi
    if ! git -C "$dest" pull --ff-only; then
      echo "kept $dest: could not fast-forward (diverged or network error)"
      return 0
    fi
    echo "updated $dest"
    return 0
  fi

  if [[ -e $dest ]]; then
    echo "kept $dest: exists but is not a git repo, skipping"
    return 0
  fi

  if ((dry_run)); then
    echo "would clone $url -> $dest"
    resolved_repo=$dest
    return 0
  fi

  if ! git clone --depth 1 "$url" "$dest"; then
    echo "skipped $dest: could not clone $url"
    return 0
  fi
  resolved_repo=$dest
  echo "cloned $dest"
}

for entry in "${LINKS[@]}"; do
  link "$DOTFILES/${entry%%:*}" "$HOME/${entry#*:}"
done

skills_repo=
for entry in "${REPOS[@]}"; do
  dest=${entry%%|*}
  rest=${entry#*|}
  sibling=${rest%%|*}
  url=${rest#*|}
  ensure_repo "$dest" "$sibling" "$url"
  if [[ $dest == agent-skills ]]; then skills_repo=$resolved_repo; fi
done

if [[ -n $skills_repo && -d $skills_repo/skills ]]; then
  for source in "$skills_repo"/skills/*/; do
    [[ -d $source ]] || continue
    name=$(basename -- "$source")
    for dest in "${SKILL_DIRS[@]}"; do
      link "$skills_repo/skills/$name" "$dest/$name"
    done
  done
elif ((dry_run)) && [[ -n $skills_repo ]]; then
  echo "would link skills from $skills_repo/skills once cloned"
fi
