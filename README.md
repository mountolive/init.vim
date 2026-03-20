# Neovim Config

I've used this config smoothly for Go, Ruby, Rust, Bash, Python and TypeScript.

## Quick Setup

Run the setup script to install all prerequisites on a fresh system (macOS or Ubuntu-like Linux):

```bash
./setup.sh
```

After the script completes, open Neovim and run:

```vim
:PlugInstall
```

## Prerequisites

### Core

| Dependency | Purpose |
|---|---|
| Neovim >= 0.10 | Editor |
| [vim-plug](https://github.com/junegunn/vim-plug) | Plugin manager |
| git | Plugin installation, version control |
| Node.js / npm | LSP servers, prettier |
| Go | gopls, delve |
| Python 3 / pip | pynvim, pyright |
| Ruby / gem | ruby-lsp |
| Rust / cargo | rust-analyzer, rusty-tags |

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
