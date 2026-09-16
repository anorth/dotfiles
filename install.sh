#!/usr/bin/env bash
# Link this repo's contents into the current machine's home directory.
# Safe to re-run: existing correct links are left alone, and anything that is
# not a symlink is reported and skipped rather than overwritten.
set -euo pipefail

DOTFILES=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

# Files to link, as "path in this repo:path under $HOME".
LINKS=(
  "bin/gflow:bin/gflow"
  "bin/replace-all:bin/replace-all"
  "git/gitconfig:.gitconfig"
  "git/ignore:.config/git/ignore"
)

# Skills live in a separate public catalog (anorth/agent-skills). Prefer a
# sibling checkout next to this repo (authoring machine); otherwise clone or
# update under ~/agent-skills (containers).
SKILLS_REPO_URL=https://github.com/anorth/agent-skills.git
SKILLS_HOME=$HOME/agent-skills
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

# Resolve or refresh the agent-skills checkout. Never fails the installer:
# report and skip when the tree is dirty, diverged, or the network is down.
ensure_skills_repo() {
  local sibling parent
  parent=$(dirname -- "$DOTFILES")
  sibling=$parent/agent-skills

  if [[ -d $sibling/.git ]]; then
    SKILLS_REPO=$sibling
    echo "using skills repo $SKILLS_REPO"
    return 0
  fi

  SKILLS_REPO=$SKILLS_HOME

  if [[ -d $SKILLS_REPO/.git ]]; then
    if ((dry_run)); then
      echo "would update skills repo $SKILLS_REPO"
      return 0
    fi
    if [[ -n $(git -C "$SKILLS_REPO" status --porcelain 2>/dev/null) ]]; then
      echo "kept $SKILLS_REPO: working tree is dirty, skipping pull"
      return 0
    fi
    if ! git -C "$SKILLS_REPO" pull --ff-only; then
      echo "kept $SKILLS_REPO: could not fast-forward (diverged or network error)"
      return 0
    fi
    echo "updated skills repo $SKILLS_REPO"
    return 0
  fi

  if [[ -e $SKILLS_REPO ]]; then
    echo "kept $SKILLS_REPO: exists but is not a git repo, skipping skills"
    SKILLS_REPO=
    return 0
  fi

  if ((dry_run)); then
    echo "would clone $SKILLS_REPO_URL -> $SKILLS_REPO"
    return 0
  fi

  if ! git clone --depth 1 "$SKILLS_REPO_URL" "$SKILLS_REPO"; then
    echo "skipped skills: could not clone $SKILLS_REPO_URL"
    SKILLS_REPO=
    return 0
  fi
  echo "cloned skills repo $SKILLS_REPO"
}

for entry in "${LINKS[@]}"; do
  link "$DOTFILES/${entry%%:*}" "$HOME/${entry#*:}"
done

ensure_skills_repo

if [[ -n ${SKILLS_REPO:-} && -d $SKILLS_REPO/skills ]]; then
  for source in "$SKILLS_REPO"/skills/*/; do
    [[ -d $source ]] || continue
    name=$(basename -- "$source")
    link "$SKILLS_REPO/skills/$name" "$SKILL_DIR/$name"
  done
elif ((dry_run)) && [[ -n ${SKILLS_REPO:-} ]]; then
  echo "would link skills from $SKILLS_REPO/skills once cloned"
fi
