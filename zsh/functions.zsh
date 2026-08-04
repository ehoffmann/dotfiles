mkcd() {
  mkdir -p "$1"
  cd "$1"
}

# -----------------------------------------------------------------------------
# linters
# -----------------------------------------------------------------------------

# Lint current diff or from $1 commit earlier
rubo() {
  if [ -n "$1" ]
  then
    git diff --name-status HEAD~"$1" HEAD | grep '^[A,M].*\.rb$' | cut -f2 | xargs -r rubocop --rails
  else
    git diff --name-only --diff-filter=d | grep '.rb$' | xargs -r rubocop --rails
  fi
}

# Lint cached
rubs() {
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop
}

rubsa() {
  git diff --name-only --cached --diff-filter=d | grep '.rb$' | xargs -r rubocop --auto-correct
}

build_ruby() {
  initial_dir="$(pwd)"
  emulate -L zsh
  set -euo pipefail

  if [ $# -ne 1 ]; then
    echo "Error: Ruby version not specified."
    echo "Usage: build_ruby <version>"
    return 1
  fi

  version="$1"
  major_minor_version="${version%.*}"
  workdir="$(mktemp -d)"

  cleanup() {
    sudo rm -rf "$workdir"
  }
  trap cleanup EXIT INT TERM

  cd "$workdir"

  wget -q --show-progress \
    "https://cache.ruby-lang.org/pub/ruby/${major_minor_version}/ruby-${version}.tar.xz"

  tar -xJf "ruby-${version}.tar.xz"
  cd "ruby-${version}"

  CFLAGS="-O3 -march=native -flto" \
  CXXFLAGS="-O3 -march=native -flto" \
  LDFLAGS="-flto" \
    ./configure --prefix="/opt/rubies/ruby-${version}" --enable-yjit

  make -j"$(nproc)"
  sudo make install
  cd "$initial_dir"
}

list_ruby_versions() {
  emulate -L zsh
  set -euo pipefail
  base_url="http://cache.ruby-lang.org/pub/ruby/index.txt"

  curl -fsSL http://cache.ruby-lang.org/pub/ruby/index.txt |
    rg 'ruby-[0-9]+\.[0-9]+\.[0-9]+\.tar\.xz' |
    sed 's/^ruby-//; s/\t.*//' |
    sort -uV
}

# Delete branches merged into either staging or main, while preserving master, main, staging, and the current branch.
git-clean-branch() {
  git fetch --prune || return

  {
    git show-ref --verify --quiet refs/heads/staging &&
      git branch --merged staging

    git show-ref --verify --quiet refs/heads/main &&
      git branch --merged main
  } |
    grep -Ev '^\*|^[[:space:]]*(master|main|staging)$' |
    sort -u |
    xargs -r git branch -d
}

git-list-mj() {
  local repo

  for repo in \
    ~/code/mj-fleet-backend \
    ~/code/mj-fleet-backend_{1..5}
  do
    [[ -d "$repo/.git" ]] || continue

    printf '\n\033[1;35m%s\033[0m' "$repo"

    if ! git -C "$repo" diff --quiet ||
       ! git -C "$repo" diff --cached --quiet; then
      printf ' \033[1;31m[dirty]\033[0m'
    fi

    printf '\n'

    git -C "$repo" for-each-ref \
      --sort=-committerdate \
      --color=always \
      --format='%(if)%(HEAD)%(then)%(color:bold green)* %(else)  %(end)%(color:bold yellow)%(refname:short)%(color:reset) %(color:cyan)%(upstream:short)%(color:reset) %(color:red)%(upstream:trackshort)%(color:reset)  %(color:blue)%(committerdate:relative)%(color:reset)  %(color:dim white)%(authorname)%(color:reset)  %(subject)' \
      refs/heads/
  done
}

update-mj-repos() {
  local repo branch
  local -a repos=(
    ~/code/mj-fleet-backend
    ~/code/mj-fleet-backend_{1..5}
  )

  for repo in "${repos[@]}"; do
    print
    print -P "%F{magenta}%B==> ${repo}%b%f"

    if ! git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
      print -P "%F{red}Not a Git repository; skipping.%f"
      continue
    fi

    (
      cd "$repo" || exit 1

      print -P "%F{cyan}Fetching backend...%f"
      git fetch --prune || exit 1

      branch=$(git branch --show-current)

      if [[ "$branch" == main ]]; then
        print -P "%F{cyan}Updating backend main...%f"
        git pull --ff-only origin main || exit 1
      else
        print -P "%F{yellow}Backend on '$branch'; not pulling main.%f"
      fi

      print -P "%F{cyan}Cleaning backend branches...%f"
      git-clean-branch || exit 1

      if ! git -C spa rev-parse --git-dir >/dev/null 2>&1; then
        print -P "%F{yellow}No SPA Git repository; skipping SPA.%f"
        exit 0
      fi

      cd spa || exit 1

      print -P "%F{cyan}Fetching SPA...%f"
      git fetch --prune || exit 1

      branch=$(git branch --show-current)

      if [[ "$branch" == main ]]; then
        print -P "%F{cyan}Updating SPA main...%f"
        git pull --ff-only origin main || exit 1
      else
        print -P "%F{yellow}SPA on '$branch'; not pulling main.%f"
      fi

      print -P "%F{green}%B✓ Repository processed%b%f"
    ) || print -P "%F{red}%B✗ Update failed for ${repo}%b%f"
  done
}

# Switch git local branches with fzf
git-switch() {
  local branch
  branch=$(git branch --format='%(refname:short)' |
    sort -u |
    fzf --prompt='Git branch> ') || return

  git switch "$branch" 2>/dev/null
}

