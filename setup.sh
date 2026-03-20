#!/usr/bin/env bash
set -euo pipefail

OS="$(uname -s)"

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

# ── Node.js / npm ───────────────────────────────────────────────────
if ! command_exists node; then
  info "Installing Node.js..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install node
  else
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
  fi
else
  info "Node.js already installed: $(node --version)"
fi

# ── Python 3 / pip ──────────────────────────────────────────────────
if ! command_exists python3; then
  info "Installing Python 3..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install python
  else
    sudo apt-get install -y python3 python3-pip python3-venv
  fi
else
  info "Python already installed: $(python3 --version)"
fi

# ── Go ───────────────────────────────────────────────────────────────
if ! command_exists go; then
  info "Installing Go..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install go
  else
    warn "Go not found. Install from https://go.dev/dl/ or run:"
    warn "  sudo snap install go --classic"
  fi
else
  info "Go already installed: $(go version)"
fi

# ── Ruby ─────────────────────────────────────────────────────────────
if ! command_exists ruby; then
  info "Installing Ruby..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install ruby
  else
    sudo apt-get install -y ruby-full
  fi
else
  info "Ruby already installed: $(ruby --version)"
fi

# ── Rust / cargo ─────────────────────────────────────────────────────
if ! command_exists rustup; then
  info "Installing Rust via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
  source "$HOME/.cargo/env"
else
  info "Rust already installed: $(rustc --version)"
fi

# ── CLI tools ────────────────────────────────────────────────────────
info "Installing CLI tools..."

if ! command_exists ag; then
  info "Installing silver searcher (ag)..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install the_silver_searcher
  else
    sudo apt-get install -y silversearcher-ag
  fi
fi

if ! command_exists jq; then
  info "Installing jq..."
  install_package jq
fi

if ! command_exists prettier; then
  info "Installing prettier..."
  npm install -g prettier
fi

if ! command_exists ctags; then
  info "Installing universal-ctags..."
  if [[ "$OS" == "Darwin" ]]; then
    brew install --HEAD universal-ctags/universal-ctags/universal-ctags
  else
    sudo apt-get install -y universal-ctags
  fi
fi

# ── LSP servers ──────────────────────────────────────────────────────
info "Installing LSP servers..."

if command_exists go; then
  info "Installing gopls..."
  go install golang.org/x/tools/gopls@latest

  info "Installing delve (Go debugger)..."
  go install github.com/go-delve/delve/cmd/dlv@latest
fi

info "Installing pyright..."
npm install -g pyright

info "Installing bash-language-server..."
npm install -g bash-language-server

if command_exists rustup; then
  info "Installing rust-analyzer..."
  rustup component add rust-analyzer

  info "Installing rust-src..."
  rustup component add rust-src

  info "Installing rusty-tags..."
  cargo install rusty-tags
fi

# ── Python packages ──────────────────────────────────────────────────
info "Installing Python packages..."
pip install --user pynvim 2>/dev/null || pip3 install --user pynvim

# ── Ruby gems ────────────────────────────────────────────────────────
info "Installing Ruby gems..."
gem install neovim ruby-lsp

# ── vim-plug ─────────────────────────────────────────────────────────
PLUG_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
if [[ ! -f "$PLUG_PATH" ]]; then
  info "Installing vim-plug..."
  curl -fLo "$PLUG_PATH" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
else
  info "vim-plug already installed"
fi

# ── Neovim directories ──────────────────────────────────────────────
mkdir -p ~/.config/nvim/swap
mkdir -p ~/.config/nvim/undo

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
