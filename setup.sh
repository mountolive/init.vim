#!/usr/bin/env bash
set -uo pipefail

OS="$(uname -s)"
ERRORS=()
SETUP_LANGS=()

ALL_COMPONENTS=(cursor nodejs python go ruby dotnet rust)

usage() {
  cat <<'EOF'
Usage: ./setup.sh [OPTIONS]

Install Neovim config prerequisites. Language/runtime steps are optional.

Options:
  --only LIST     Comma- or space-separated components to install
                  (cursor nodejs python go ruby dotnet rust)
  --help          Show this help

Environment:
  SETUP_LANGUAGES   Same as --only (e.g. nodejs,go,rust)

Always installed: git, Neovim, vim-plug, config symlink, CLI tools (ag, jq, ctags).
Interactive prompt when stdin is a TTY and no --only / SETUP_LANGUAGES is set.

Examples:
  ./setup.sh --only nodejs,go,rust
  SETUP_LANGUAGES=nodejs,python ./setup.sh
EOF
}

wants() {
  local c="$1"
  local x
  for x in "${SETUP_LANGS[@]}"; do
    [[ "$x" == "$c" ]] && return 0
  done
  return 1
}

needs_asdf_lang() {
  wants nodejs || wants python || wants ruby || wants dotnet
}

parse_components() {
  local raw="${1:-${SETUP_LANGUAGES:-}}"
  if [[ -z "$raw" ]]; then
    if [[ -t 0 ]]; then
      prompt_components_interactive
    else
      SETUP_LANGS=("${ALL_COMPONENTS[@]}")
    fi
    return
  fi
  raw="${raw//,/ }"
  read -ra SETUP_LANGS <<< "$raw"
  local c valid=()
  for c in "${SETUP_LANGS[@]}"; do
    case "$c" in
      cursor|nodejs|python|go|ruby|dotnet|rust) valid+=("$c") ;;
      *)
        warn "Unknown component '$c' (ignored)"
        ;;
    esac
  done
  SETUP_LANGS=("${valid[@]}")
}

prompt_components_interactive() {
  info "Select components to install."
  local i=1 c
  for c in "${ALL_COMPONENTS[@]}"; do
    printf '  %s) %s\n' "$i" "$c"
    ((i++)) || true
  done
  info "Press Enter for all, or:"
  info "  - numbers to SKIP (e.g. 4 6 skips ruby and rust)"
  info "  - names to install only (e.g. nodejs go rust)"
  read -r -p 'Choice: ' reply
  reply="${reply//,/ }"
  if [[ -z "$reply" ]]; then
    SETUP_LANGS=("${ALL_COMPONENTS[@]}")
    return
  fi
  if [[ "$reply" =~ ^[0-9[:space:]]+$ ]]; then
    local kept=() num=1
    for c in "${ALL_COMPONENTS[@]}"; do
      local skip=0 n
      for n in $reply; do
        [[ "$n" == "$num" ]] && skip=1
      done
      [[ "$skip" -eq 0 ]] && kept+=("$c")
      ((num++)) || true
    done
    SETUP_LANGS=("${kept[@]}")
    return
  fi
  read -ra SETUP_LANGS <<< "$reply"
  local valid=()
  for c in "${SETUP_LANGS[@]}"; do
    case "$c" in
      cursor|nodejs|python|go|ruby|dotnet|rust) valid+=("$c") ;;
      *) warn "Unknown component '$c' (ignored)" ;;
    esac
  done
  SETUP_LANGS=("${valid[@]}")
}

info()  { printf "\033[1;34m=> %s\033[0m\n" "$*"; }
warn()  { printf "\033[1;33m=> %s\033[0m\n" "$*"; }
error() { printf "\033[1;31m=> %s\033[0m\n" "$*"; exit 1; }

command_exists() { command -v "$1" &>/dev/null; }

install_package() {
  local name="$1"
  if [[ "$OS" == "Darwin" ]]; then
    brew install "$name"
  else
    sudo apt-get install -y "$name"
  fi
}

install_linux_build_deps() {
  info "Installing Linux build dependencies (gcc, make, headers)..."
  sudo apt-get install -y \
    build-essential \
    pkg-config \
    curl \
    git \
    libssl-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    libxml2-dev \
    libxml2-utils \
    libffi-dev \
    liblzma-dev \
    libyaml-dev \
    libicu-dev \
    autoconf \
    bison \
    libgdbm-dev \
    libnss3-dev \
    || ERRORS+=("Linux build dependencies (apt)")
}

asdf_set_global() {
  asdf set -u "$1" "$2" 2>/dev/null || asdf global "$1" "$2"
}

asdf_install_latest() {
  local plugin="$1"
  local label="${2:-$plugin}"
  local version_prefix="${3:-}"
  asdf plugin add "$plugin" 2>/dev/null || true
  local latest
  if [[ -n "$version_prefix" ]]; then
    latest="$(asdf latest "$plugin" "$version_prefix")" || { warn "Could not resolve latest $label ${version_prefix}.x version"; return 1; }
  else
    latest="$(asdf latest "$plugin")" || { warn "Could not resolve latest $label version"; return 1; }
  fi
  info "Installing $label ${latest} via asdf..."
  asdf install "$plugin" "$latest"
  asdf_set_global "$plugin" "$latest"
  asdf reshim "$plugin"
}

setup_shell_asdf() {
  local rc marker block
  for rc in "$HOME/.zshrc" "$HOME/.bashrc"; do
    touch "$rc"
    marker="# asdf – managed by setup.sh"
    if grep -qF "$marker" "$rc"; then
      continue
    fi
    block=$(cat <<ZSHEOF

$marker
[[ -f "$ASDF_SH" ]] && . "$ASDF_SH"
export PATH="\${ASDF_DATA_DIR:-\$HOME/.asdf}/shims:\$PATH"
ZSHEOF
)
    printf '%s\n' "$block" >> "$rc"
    info "Added asdf init to $rc"
  done
}

# ── CLI args ─────────────────────────────────────────────────────────
ONLY_ARG=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    --only) ONLY_ARG="${2:-}"; shift 2 ;;
    *) error "Unknown option: $1 (try --help)" ;;
  esac
done

parse_components "$ONLY_ARG"

if [[ ${#SETUP_LANGS[@]} -eq 0 ]]; then
  error "No components selected. Use --only or pick items in the prompt."
fi

info "Installing components: ${SETUP_LANGS[*]}"

# ── Package manager ──────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
  if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
else
  info "Updating apt..."
  sudo apt-get update -qq
  if wants python || wants ruby || wants rust || wants nodejs || wants dotnet; then
    install_linux_build_deps
  fi
fi

# ── Cursor ───────────────────────────────────────────────────────────
if wants cursor; then
  if [[ "$OS" == "Darwin" ]]; then
    if ! [[ -d "/Applications/Cursor.app" ]]; then
      info "Installing Cursor..."
      brew install --cask cursor || ERRORS+=("Cursor app (brew cask)")
    else
      info "Cursor already installed"
    fi
  else
    if ! command_exists cursor; then
      info "Installing Cursor via snap..."
      sudo snap install cursor --edge || ERRORS+=("Cursor app (snap)")
    else
      info "Cursor already installed"
    fi
  fi

  if ! command_exists cursor-agent && ! command_exists cursor; then
    info "Installing Cursor CLI..."
    (curl https://cursor.com/install -fsS | bash) || ERRORS+=("Cursor CLI (install script)")
  else
    info "Cursor CLI already installed"
  fi

  if [[ "$OS" == "Darwin" ]]; then
    CURSOR_CLI_CASK_DIR="$(find "$HOME/Library/Caches/Homebrew/Caskroom/cursor-cli" \
      /usr/local/Caskroom/cursor-cli /opt/homebrew/Caskroom/cursor-cli \
      -maxdepth 2 -name "dist-package" 2>/dev/null | head -1 || true)"
    if [[ -n "$CURSOR_CLI_CASK_DIR" ]]; then
      info "Removing quarantine from Cursor CLI dist-package..."
      xattr -dr com.apple.quarantine "$CURSOR_CLI_CASK_DIR" 2>/dev/null || true
    fi
  fi
fi

# ── Neovim ───────────────────────────────────────────────────────────
if ! command_exists nvim; then
  info "Installing Neovim..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install neovim
  else
    sudo apt-get install -y neovim
  fi
else
  info "Neovim already installed: $(nvim --version | head -1)"
fi

# ── Git ──────────────────────────────────────────────────────────────
if ! command_exists git; then
  info "Installing git..."
  install_package git
fi

if command_exists git; then
  info "Configuring global git..."
  git config --global core.editor vim
  git config --global core.autocrlf input
  git config --global alias.rc '!r() { git checkout $(git branch | grep -e "$1" | head -n1); }; r'
  git config --global alias.cb '!cb() { git rev-parse --abbrev-ref HEAD; }; cb'
  git config --global alias.cms '!cms() { git for-each-ref --sort=-committerdate refs/heads/ | head -n20; }; cms'
fi

# ── asdf ─────────────────────────────────────────────────────────────
if needs_asdf_lang; then
  if ! command_exists asdf; then
    info "Installing asdf..."
    if [[ "$OS" == "Darwin" ]]; then
      brew install asdf
    else
      if [[ ! -d "$HOME/.asdf" ]]; then
        git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" \
          --branch "$(git ls-remote --tags --sort=version:refname https://github.com/asdf-vm/asdf.git | tail -1 | sed 's/.*\///')"
      fi
    fi
  fi

  ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
  ASDF_SHIMS="$ASDF_DATA_DIR/shims"

  if [[ "$OS" == "Darwin" ]]; then
    ASDF_SH="$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh"
  else
    ASDF_SH="$HOME/.asdf/asdf.sh"
  fi
  # shellcheck source=/dev/null
  [[ -f "$ASDF_SH" ]] && source "$ASDF_SH"
  export PATH="$ASDF_SHIMS:$PATH"
  setup_shell_asdf
fi

# ── Node.js (asdf) ───────────────────────────────────────────────────
if wants nodejs; then
  if command_exists asdf; then
    (asdf_install_latest nodejs "Node.js") || ERRORS+=("Node.js (asdf)")
  else
    warn "asdf not found; skipping Node.js"
    ERRORS+=("Node.js (asdf not available)")
  fi
fi

# ── Python 3 (asdf) ──────────────────────────────────────────────────
if wants python; then
  if command_exists asdf; then
    (asdf_install_latest python "Python" "3") || ERRORS+=("Python (asdf)")
  else
    warn "asdf not found; skipping Python"
    ERRORS+=("Python (asdf not available)")
  fi
fi

# ── Go ───────────────────────────────────────────────────────────────
if wants go; then
  if ! command_exists go; then
    info "Installing Go..."
    if [[ "$OS" == "Darwin" ]]; then
      brew install go || ERRORS+=("Go (brew)")
    else
      if command_exists snap; then
        sudo snap install go --classic || ERRORS+=("Go (snap)")
      else
        warn "Go not found. Install from https://go.dev/dl/"
        ERRORS+=("Go (manual install required on Linux)")
      fi
    fi
  else
    info "Go already installed: $(go version)"
    if go env GOROOT 2>/dev/null | grep -q "$(go env GOPATH 2>/dev/null)"; then
      warn "GOPATH and GOROOT appear to be the same; see https://go.dev/wiki/InstallTroubleshooting"
    fi
  fi
fi

# ── Ruby (asdf) ──────────────────────────────────────────────────────
if wants ruby; then
  if command_exists asdf; then
    (
      if [[ "$OS" == "Darwin" ]]; then
        brew install libyaml 2>/dev/null || true
        export RUBY_CONFIGURE_OPTS="--with-libyaml-dir=$(brew --prefix libyaml)"
      else
        sudo apt-get install -y libyaml-dev || true
      fi
      asdf_install_latest ruby "Ruby" "3"
    ) || ERRORS+=("Ruby (asdf)")
  else
    warn "asdf not found; skipping Ruby"
    ERRORS+=("Ruby (asdf not available)")
  fi
fi

# ── .NET SDK / C# (asdf) + csharp-ls ─────────────────────────────────
if wants dotnet; then
  if command_exists asdf; then
    (
      asdf_install_latest dotnet "dotnet SDK"
      if [[ "$OS" != "Darwin" ]]; then
        sudo apt-get install -y libicu-dev || true
      fi
      info "Installing csharp-ls (C# LSP)..."
      asdf exec dotnet tool install --global csharp-ls 2>/dev/null || asdf exec dotnet tool update --global csharp-ls
    ) || ERRORS+=(".NET SDK + csharp-ls (asdf)")
  else
    warn "asdf not found; skipping .NET SDK"
    ERRORS+=(".NET SDK (asdf not available)")
  fi
fi

# ── Rust / cargo ─────────────────────────────────────────────────────
if wants rust; then
  if ! command_exists rustup; then
    info "Installing Rust via rustup..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || ERRORS+=("Rust (rustup)")
    # shellcheck source=/dev/null
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  else
    info "Rust already installed: $(rustc --version)"
    # shellcheck source=/dev/null
    [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
  fi
fi

# Refresh PATH for asdf shims after installs
if needs_asdf_lang && [[ -f "${ASDF_SH:-}" ]]; then
  # shellcheck source=/dev/null
  source "$ASDF_SH"
  export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"
fi

NPM="$(command -v npm || true)"

# ── CLI tools ────────────────────────────────────────────────────────
info "Installing CLI tools..."

if ! command_exists ag; then
  info "Installing silver searcher (ag)..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install the_silver_searcher || ERRORS+=("ag (brew)")
  else
    sudo apt-get install -y silversearcher-ag || ERRORS+=("ag (apt)")
  fi
fi

if ! command_exists jq; then
  info "Installing jq..."
  install_package jq || ERRORS+=("jq")
fi

if [[ -n "$NPM" ]]; then
  if ! command_exists prettier; then
    info "Installing prettier..."
    "$NPM" install -g prettier || ERRORS+=("prettier (npm)")
  fi

  if ! command_exists tree-sitter; then
    info "Installing tree-sitter-cli..."
    "$NPM" install -g tree-sitter-cli || ERRORS+=("tree-sitter-cli (npm)")
  fi
elif wants nodejs; then
  warn "npm not available; skipping prettier and tree-sitter-cli"
  ERRORS+=("npm tools (npm not available)")
fi

if ! command_exists ctags; then
  info "Installing universal-ctags..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install --HEAD universal-ctags/universal-ctags/universal-ctags || ERRORS+=("universal-ctags (brew)")
  else
    sudo apt-get install -y universal-ctags || ERRORS+=("universal-ctags (apt)")
  fi
fi

# ── LSP servers ──────────────────────────────────────────────────────
info "Installing LSP servers..."

if wants go && command_exists go; then
  (
    info "Installing gopls..."
    go install golang.org/x/tools/gopls@latest
    info "Installing delve (Go debugger)..."
    go install github.com/go-delve/delve/cmd/dlv@latest
  ) || ERRORS+=("gopls / delve (go install)")
fi

if [[ -n "$NPM" ]]; then
  if wants python; then
    "$NPM" install -g pyright || ERRORS+=("pyright (npm)")
  fi
  "$NPM" install -g bash-language-server || ERRORS+=("bash-language-server (npm)")
elif wants python; then
  ERRORS+=("pyright (npm not available)")
fi

if wants rust && command_exists rustup; then
  (
    info "Installing rust-analyzer..."
    rustup component add rust-analyzer
    info "Installing rust-src..."
    rustup component add rust-src
    if command_exists cc || command_exists gcc; then
      info "Installing rusty-tags..."
      cargo install rusty-tags
    else
      warn "No C compiler (cc/gcc); skipping rusty-tags"
      ERRORS+=("rusty-tags (no C compiler)")
    fi
  ) || ERRORS+=("rust-analyzer / rusty-tags")
fi

# ── Python packages ──────────────────────────────────────────────────
if wants python; then
  if command_exists asdf && asdf current python &>/dev/null; then
    info "Installing Python packages..."
    asdf exec pip install --user pynvim || ERRORS+=("pynvim (pip)")
  elif command_exists pip || command_exists pip3; then
    info "Installing Python packages..."
    pip install --user pynvim 2>/dev/null || pip3 install --user pynvim || ERRORS+=("pynvim (pip)")
  else
    warn "pip not available; skipping pynvim"
    ERRORS+=("pynvim (pip not available)")
  fi
fi

# ── Ruby gems ────────────────────────────────────────────────────────
if wants ruby; then
  if command_exists asdf && asdf current ruby &>/dev/null; then
    info "Installing Ruby gems..."
    asdf exec gem install neovim ruby-lsp || ERRORS+=("neovim / ruby-lsp (gem)")
  elif command_exists gem; then
    info "Installing Ruby gems..."
    gem install neovim ruby-lsp || ERRORS+=("neovim / ruby-lsp (gem)")
  else
    warn "gem not available; skipping Ruby gems"
    ERRORS+=("neovim / ruby-lsp (gem not available)")
  fi
fi

# ── vim-plug ─────────────────────────────────────────────────────────
PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
if [[ ! -f "$PLUG_PATH" ]]; then
  info "Installing vim-plug..."
  curl -fLo "$PLUG_PATH" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim || ERRORS+=("vim-plug (curl)")
else
  info "vim-plug already installed"
fi

# ── Neovim config symlink ────────────────────────────────────────────
NVIM_CONFIG_DIR="$HOME/.config/nvim"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -L "$NVIM_CONFIG_DIR" ]]; then
  info "Neovim config symlink already exists: $NVIM_CONFIG_DIR -> $(readlink "$NVIM_CONFIG_DIR")"
elif [[ -d "$NVIM_CONFIG_DIR" ]]; then
  warn "$NVIM_CONFIG_DIR exists as a real directory; backing up to ${NVIM_CONFIG_DIR}.bak"
  mv "$NVIM_CONFIG_DIR" "${NVIM_CONFIG_DIR}.bak"
  ln -s "$REPO_DIR" "$NVIM_CONFIG_DIR"
  info "Symlinked $REPO_DIR -> $NVIM_CONFIG_DIR"
else
  mkdir -p "$(dirname "$NVIM_CONFIG_DIR")"
  ln -s "$REPO_DIR" "$NVIM_CONFIG_DIR"
  info "Symlinked $REPO_DIR -> $NVIM_CONFIG_DIR"
fi

mkdir -p "$NVIM_CONFIG_DIR/swap"
mkdir -p "$NVIM_CONFIG_DIR/undo"

# ── rusty-tags config ────────────────────────────────────────────────
if command_exists rusty-tags; then
  mkdir -p ~/.rusty-tags
  if [[ ! -f ~/.rusty-tags/config.toml ]]; then
    info "Creating rusty-tags config..."
    cat > ~/.rusty-tags/config.toml <<'TOML'
vi_tags = ".rstags"
emacs_tags = "rusty-tags.emacs"
ctags_exe = ""
ctags_options = ""
TOML
  fi
fi

# ── Done ─────────────────────────────────────────────────────────────
echo ""
info "Setup complete!"
info ""
info "Next steps:"
info "  1. Reload shell: source ~/.zshrc  (or source ~/.bashrc)"
info "  2. Open Neovim and run :PlugInstall"
if wants nodejs; then
  info "     (PlugInstall needs npm/make in PATH for LuaSnip and markdown-preview)"
fi
info "  3. Add to your shell profile if needed:"
info "     export RUST_SRC_PATH=\$(rustc --print sysroot)/lib/rustlib/src/rust/library/"
info "     export PATH=\$PATH:\$(go env GOPATH)/bin"
info "     export PATH=\$PATH:\$HOME/.dotnet/tools"

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  printf "\033[1;31m=> The following steps FAILED (skipped):\033[0m\n"
  for e in "${ERRORS[@]}"; do
    printf "\033[1;31m   - %s\033[0m\n" "$e"
  done
fi
