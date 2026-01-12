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

install_ruby() {
  # Usage: install_ruby <version>
  # Example: install_ruby 3.3.0

  if [ -z "$1" ]; then
    echo "Error: Ruby version not specified."
    echo "Usage: install_ruby <version>"
    return 1
  fi

  local version="$1"
  # Extract the major and minor version (e.g., 3.3 from 3.3.0)
  local major_minor_version="${version%.*}"

  # Install dependencies (uncomment if not already installed)
  # sudo apt install -y build-essential bison zlib1g-dev libyaml-dev libssl-dev libgdbm-dev libreadline-dev libffi-dev

  wget "https://cache.ruby-lang.org/pub/ruby/${major_minor_version}/ruby-${version}.tar.xz"
  tar -xJvf "ruby-${version}.tar.xz"
  rm "ruby-${version}.tar.xz"
  cd "ruby-${version}"
  CFLAGS="-O3 -march=native -flto" \
    CXXFLAGS="-O3 -march=native -flto" \
    LDFLAGS="-flto" \
    ./configure --prefix="/opt/rubies/ruby-${version}" --enable-yjit
  make -j"$(nproc)"
  sudo make install
  cd ..
  sudo rm -rf "ruby-${version}"
}
