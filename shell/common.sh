# POSIX shell config for bash and zsh. No zsh syntax, no oh-my-zsh.
# Source this after oh-my-zsh when that is loaded: its git plugin defines
# `g` as `git`, and the aliases below are meant to replace that.
# `gh` is left unset so it stays the GitHub CLI.

# zsh does not put ~/.local/bin on PATH. Some Linux login profiles do, via
# .profile or ~/.zshenv. Prepend it when the directory exists and is not listed.
if [ -d "$HOME/.local/bin" ]; then
  case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH" ;;
  esac
fi

# Git aliases
alias g-b="git branch"
alias g='git branch && git status -sb'
alias gs='git status'
alias gp='git pull'
alias gpr='git pull --rebase'
alias gpp='git pull --rebase && git push'
alias gf='git fetch'
alias gb='git branch'
alias gbd='git branch -d'
alias gbD='git branch -D'
alias ga='git add'
alias gcb='git checkout -b'
alias gc='git commit -m'
alias gca='git commit --amend'
alias gcv='git commit --no-verify'
alias gd='git diff --color-words'
alias gdc='git diff --cached -w'
alias gdw='git diff --no-ext-diff --word-diff'
alias gdv='git diff'
alias gl='git log --color --decorate'
alias gt='git tag'
alias grc='git rebase --continue'
alias grs='git rebase --skip'
alias gri='git rebase --interactive'
alias gsl='git stash list'
alias gss='git stash save'
alias gg='git log --decorate --oneline --graph --date-order --all'

# Deletes local branches already merged into main, except the current one.
git_clean_merged() {
  git checkout main &&
    git pull &&
    git branch --merged main | grep -vE '^\*|main' | xargs -n 1 git branch -d
}

# List directories under the current path and cd to the one fzf picks.
# Cancel leaves the working directory unchanged.
j() {
  command -v fzf >/dev/null || { echo "j: fzf is required" >&2; return 1; }
  dir=$(find . -type d 2>/dev/null | fzf) || return
  cd "$dir"
}

# Kill whatever is listening on a TCP port.
killport() {
  command -v lsof >/dev/null || { echo "killport: lsof is required" >&2; return 1; }
  lsof -ti tcp:"$1" | xargs kill -9
}

# Extract an archive based on its suffix.
extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.bz2)   tar xjf "$1"    ;;
      *.tar.gz)    tar xzf "$1"    ;;
      *.bz2)       bunzip2 "$1"    ;;
      *.rar)       unrar x "$1"    ;;
      *.gz)        gunzip "$1"     ;;
      *.tar)       tar xf "$1"     ;;
      *.tbz2)      tar xjf "$1"    ;;
      *.tgz)       tar xzf "$1"    ;;
      *.zip)       unzip "$1"      ;;
      *.Z)         uncompress "$1" ;;
      *.7z)        7z x "$1"       ;;
      *)           echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}
