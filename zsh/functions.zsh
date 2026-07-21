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
