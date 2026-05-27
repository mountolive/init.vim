#!/usr/bin/env bash
set -uo pipefail

OS="$(uname -s)"
ERRORS=()

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

# ── Package manager ──────────────────────────────────────────────────
if [[ "$OS" == "Darwin" ]]; then
  if ! command_exists brew; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
else
  info "Updating apt..."
  sudo apt-get update -qq
fi

# ── Cursor app ───────────────────────────────────────────────────────
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

# ── Cursor CLI (agent) ────────────────────────────────────────────────
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

# ── asdf ─────────────────────────────────────────────────────────────
if ! command_exists asdf; then
  info "Installing asdf..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install asdf
  else
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" \
      --branch "$(git ls-remote --tags --sort=version:refname https://github.com/asdf-vm/asdf.git | tail -1 | sed 's/.*\///')"
  fi
fi

ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
ASDF_SHIMS="$ASDF_DATA_DIR/shims"

if [[ "$OS" == "Darwin" ]]; then
  ASDF_SH="$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh"
else
  ASDF_SH="$HOME/.asdf/asdf.sh"
fi
# source asdf.sh only for older script-based installs; new binary installs skip this
# shellcheck source=/dev/null
[[ -f "$ASDF_SH" ]] && source "$ASDF_SH"
export PATH="$ASDF_SHIMS:$PATH"

ZSHRC="$HOME/.zshrc"
touch "$ZSHRC"
ZSHRC_MARKER="# asdf – managed by setup.sh"
if ! grep -qF "$ZSHRC_MARKER" "$ZSHRC"; then
  cat >> "$ZSHRC" <<ZSHEOF

$ZSHRC_MARKER
[[ -f "$ASDF_SH" ]] && . "$ASDF_SH"
export PATH="\${ASDF_DATA_DIR:-\$HOME/.asdf}/shims:\$PATH"
ZSHEOF
  info "Added asdf init to $ZSHRC"
fi

# ── Node.js (asdf) ───────────────────────────────────────────────────
if command_exists asdf; then
  (asdf_install_latest nodejs "Node.js") || ERRORS+=("Node.js (asdf)")
else
  warn "asdf not found; skipping Node.js"
  ERRORS+=("Node.js (asdf not available)")
fi

# ── Python 3 (asdf) ──────────────────────────────────────────────────
if command_exists asdf; then
  (asdf_install_latest python "Python") || ERRORS+=("Python (asdf)")
else
  warn "asdf not found; skipping Python"
  ERRORS+=("Python (asdf not available)")
fi

# ── Go ───────────────────────────────────────────────────────────────
if ! command_exists go; then
  info "Installing Go..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install go || ERRORS+=("Go (brew)")
  else
    warn "Go not found. Install from https://go.dev/dl/ or run:"
    warn "  sudo snap install go --classic"
    ERRORS+=("Go (manual install required on Linux)")
  fi
else
  info "Go already installed: $(go version)"
fi

# ── Ruby (asdf) ──────────────────────────────────────────────────────
if command_exists asdf; then
  (
    if [[ "$OS" == "Darwin" ]]; then
      brew install libyaml 2>/dev/null || true
      export RUBY_CONFIGURE_OPTS="--with-libyaml-dir=$(brew --prefix libyaml)"
    fi
    asdf_install_latest ruby "Ruby" "3"
  ) || ERRORS+=("Ruby (asdf)")
else
  warn "asdf not found; skipping Ruby"
  ERRORS+=("Ruby (asdf not available)")
fi

# ── .NET SDK / C# (asdf) + OmniSharp ────────────────────────────────
if command_exists asdf; then
  (
    asdf_install_latest dotnet "dotnet SDK"
    info "Installing csharp-ls (C# LSP)..."
    asdf exec dotnet tool install --global csharp-ls 2>/dev/null || asdf exec dotnet tool update --global csharp-ls
  ) || ERRORS+=(".NET SDK + OmniSharp (asdf)")
else
  warn "asdf not found; skipping .NET SDK"
  ERRORS+=(".NET SDK (asdf not available)")
fi

# ── Rust / cargo ─────────────────────────────────────────────────────
if ! command_exists rustup; then
  info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y || ERRORS+=("Rust (rustup)")
  # shellcheck source=/dev/null
  [[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"
else
  info "Rust already installed: $(rustc --version)"
fi

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

NPM="$(command -v npm || true)"
if [[ -n "$NPM" ]]; then
  if ! command_exists prettier; then
    info "Installing prettier..."
    "$NPM" install -g prettier || ERRORS+=("prettier (npm)")
  fi

  if ! command_exists tree-sitter; then
    info "Installing tree-sitter-cli..."
    "$NPM" install -g tree-sitter-cli || ERRORS+=("tree-sitter-cli (npm)")
  fi
else
  warn "npm not available; skipping prettier"
  ERRORS+=("prettier (npm not available)")
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

if command_exists go; then
  (
    info "Installing gopls..."
    go install golang.org/x/tools/gopls@latest
    info "Installing delve (Go debugger)..."
    go install github.com/go-delve/delve/cmd/dlv@latest
  ) || ERRORS+=("gopls / delve (go install)")
fi

if [[ -n "$NPM" ]]; then
  "$NPM" install -g pyright || ERRORS+=("pyright (npm)")
  "$NPM" install -g bash-language-server || ERRORS+=("bash-language-server (npm)")
else
  warn "npm not available; skipping pyright and bash-language-server"
  ERRORS+=("pyright / bash-language-server (npm not available)")
fi

if command_exists rustup; then
  (
    info "Installing rust-analyzer..."
    rustup component add rust-analyzer
    info "Installing rust-src..."
    rustup component add rust-src
    info "Installing rusty-tags..."
    cargo install rusty-tags
  ) || ERRORS+=("rust-analyzer / rusty-tags")
fi


# ── Python packages ──────────────────────────────────────────────────
if command_exists pip || command_exists pip3; then
  info "Installing Python packages..."
  pip install --user pynvim 2>/dev/null || pip3 install --user pynvim || ERRORS+=("pynvim (pip)")
else
  warn "pip not available; skipping pynvim"
  ERRORS+=("pynvim (pip not available)")
fi

# ── Ruby gems ────────────────────────────────────────────────────────
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

# ── Neovim directories ──────────────────────────────────────────────
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
info "  1. Open Neovim and run :PlugInstall"
info "  2. Add to your shell profile (~/.bashrc or ~/.zshrc):"
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
