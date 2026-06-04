# Neovim Config

I've used this config smoothly for Go, Ruby, Rust, Bash, Python, TypeScript and C#.

## Quick Setup

Run the setup script to install prerequisites on a fresh system (macOS or Ubuntu-like Linux):

```bash
./setup.sh
```

By default (interactive terminal), you choose which components to install. Skip languages you do not need (e.g. on WSL without Ruby):

```bash
./setup.sh --only nodejs,go,rust
# or
SETUP_LANGUAGES=nodejs,go,rust ./setup.sh
```

Components: `cursor`, `nodejs`, `python`, `go`, `ruby`, `dotnet`, `rust`. Always installed: git (with global `core.editor`, `core.autocrlf`, and aliases `rc` / `cb` / `cms`), Neovim, vim-plug, config symlink, and CLI tools (`ag`, `jq`, ctags).

Interactive prompt: press Enter for all, enter numbers to **skip** (e.g. `4` skips ruby), or type names to install only those (e.g. `nodejs go rust`).

The script installs [asdf](https://asdf-vm.com/) when a managed runtime is selected and appends asdf init to `~/.zshrc` and `~/.bashrc`.

After the script completes, reload your shell so the asdf shims take effect:

```bash
source ~/.zshrc
```

Then verify the managed runtimes are active:

```bash
which ruby    # should point to ~/.asdf/shims/ruby
which python  # should point to ~/.asdf/shims/python
which node    # should point to ~/.asdf/shims/node
which dotnet  # should point to ~/.asdf/shims/dotnet
```

Then open Neovim and run:

```vim
:PlugInstall
```

## WSL (Ubuntu)

The setup script treats WSL Ubuntu as Linux (`uname -s` is `Linux`). Run it from inside your WSL distro:

```bash
cd /path/to/init.vim
chmod +x setup.sh
./setup.sh
```

Reload the shell after the script finishes:

```bash
source ~/.bashrc   # or source ~/.zshrc
```

Verify asdf shims (same as macOS):

```bash
which ruby    # ~/.asdf/shims/ruby
which python  # ~/.asdf/shims/python
which node    # ~/.asdf/shims/node
which dotnet  # ~/.asdf/shims/dotnet
```

Then in WSL: `nvim` and `:PlugInstall`.

### What works well on WSL

- `apt` packages: git, neovim, `ag`, `jq`, universal-ctags, and similar
- asdf (cloned to `~/.asdf`) and runtimes: Node.js, Python, Ruby 3.x, .NET
- Cursor CLI via the official install script
- Symlink `~/.config/nvim` → this repo
- Neovim and plugins inside WSL

### Common WSL caveats

| Step | On WSL |
|------|--------|
| **Cursor desktop app** | The script uses `snap install cursor --edge`. Snap is often missing or awkward in WSL. Use Cursor on Windows and the CLI inside WSL instead. |
| **Go** | Not installed automatically on Linux. Install manually, e.g. `sudo snap install go --classic` or from [go.dev/dl](https://go.dev/dl/). |
| **Ruby (psych)** | macOS installs `libyaml` via Homebrew; on Ubuntu you may need `sudo apt install -y libyaml-dev` before Ruby builds, then re-run setup or install Ruby via asdf again. |
| **Neovim version** | `apt install neovim` may be older than 0.10 on some Ubuntu releases. Use a newer build (PPA, AppImage, or build from source) if LSP or treesitter misbehaves. |
| **Markdown preview** | Opens a browser. Use WSLg, set `BROWSER` to a Windows browser, or preview from Windows. |
| **sudo** | The script runs `sudo apt-get`; your WSL user needs sudo access. |

### Suggested WSL workflow

1. Run with only what you need, e.g. `./setup.sh --only nodejs,go,rust` (skips ruby and dotnet).
2. The script installs `build-essential`, `libicu-dev`, and other headers on Linux when those components are selected.
3. Read any failed steps printed at the end and re-run after fixing apt packages.
4. **Before `:PlugInstall`**, reload the shell so `npm` and `make` are on PATH (`source ~/.bashrc`). Exit status 127 on LuaSnip or markdown-preview usually means `make` or `npm` was missing in that session.
5. Use **Cursor on Windows** for the GUI; use the **`<C-t>`** terminal in Neovim plus `cursor` / `cursor-agent` in WSL for the agent CLI.

Example WSL install without Ruby or .NET:

```bash
./setup.sh --only nodejs,python,go,rust
source ~/.bashrc
nvim -c 'PlugInstall' -c qa
```

## Prerequisites

### Core

| Dependency | Purpose |
|---|---|
| Neovim >= 0.10 | Editor |
| [vim-plug](https://github.com/junegunn/vim-plug) | Plugin manager |
| git | Plugin installation, version control |
| [Cursor](https://cursor.com) | AI editor (`<C-t>` terminal for the agent CLI) |
| [Cursor CLI](https://cursor.com/docs/cli/overview) | Agent in terminal (`cursor-agent`) |
| [asdf](https://asdf-vm.com/) | Runtime version manager (Node.js, Python, Ruby, .NET) |
| Node.js / npm | LSP servers, prettier |
| Go | gopls, delve |
| Python 3 / pip | pynvim, pyright |
| Ruby (latest 3.x) / gem | ruby-lsp |
| Rust / cargo | rust-analyzer, rusty-tags |
| .NET SDK | C# / csharp-ls LSP |

### CLI Tools

| Tool | Purpose | Install |
|---|---|---|
| [ag](https://github.com/ggreer/the_silver_searcher) (silver searcher) | Fuzzy search, ack.vim | `brew install the_silver_searcher` / `apt install silversearcher-ag` |
| [fzf](https://github.com/junegunn/fzf) | Fuzzy file finder | Installed automatically by vim-plug |
| [jq](https://github.com/jqlang/jq) | JSON formatting (`,Z`) | `brew install jq` / `apt install jq` |
| [prettier](https://prettier.io/) | Markdown formatting on save | `npm install -g prettier` |
| [universal-ctags](https://github.com/universal-ctags/ctags) | Tag generation | `brew install --HEAD universal-ctags/universal-ctags/universal-ctags` / build from source |

### LSP Servers

| Server | Language | Install |
|---|---|---|
| [gopls](https://pkg.go.dev/golang.org/x/tools/gopls) | Go | `go install golang.org/x/tools/gopls@latest` |
| [delve](https://github.com/go-delve/delve) | Go (debugger) | `go install github.com/go-delve/delve/cmd/dlv@latest` |
| [pyright](https://github.com/microsoft/pyright) | Python | `npm install -g pyright` |
| [bash-language-server](https://github.com/bash-lsp/bash-language-server) | Bash | `npm install -g bash-language-server` |
| [rust-analyzer](https://rust-analyzer.github.io/) | Rust | `rustup component add rust-analyzer` |
| [ruby-lsp](https://github.com/Shopify/ruby-lsp) | Ruby | `gem install ruby-lsp` |
| [csharp-ls](https://github.com/razzmatazz/csharp-language-server) | C# | `dotnet tool install --global csharp-ls` |
| typescript-tools.nvim | TypeScript | Bundled as Neovim plugin |

### Python

```bash
pip install pynvim
```

### Ruby

```bash
gem install neovim ruby-lsp
```

### Rust Extras

For ctags support in Rust projects:

```bash
cargo install rusty-tags
rustup component add rust-src
```

Add to your shell profile (`~/.bashrc`, `~/.zshrc`, etc.):

```bash
export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/library/
```

Create `~/.rusty-tags/config.toml`:

```toml
vi_tags = ".rstags"
emacs_tags = "rusty-tags.emacs"
ctags_exe = ""
ctags_options = ""
```

Remember to add `*.*tags` to your `.gitignore`.

### TreeSitter

Treesitter parsers are installed automatically on startup for: bash, css, go, gomod,
gosum, html, javascript, json, lua, markdown, python, ruby, rust, toml, typescript,
tsx, vim, vimdoc, yaml.
