# NEOVIM config

I've use this config smoothly for Go, Ruby, Rust, Bash and Python

## Bash

`npm i -g bash-language-server`

## Python

`pip install pynvim flake8`

when using pyright

`npm i -g pyright`

## Ruby

`gem install neovim`

## Rust

### Ctags

`brew install --HEAD universal-ctags/universal-ctags/universal-ctags`

`cargo install rusty-tags`

`rustup component add rust-src`

```
// Add this to your ~/.*sh file
export RUST_SRC_PATH=$(rustc --print sysroot)/lib/rustlib/src/rust/library/

// And source it
```

Create `~/.rusty-tags/config.toml`

And add:

```
# the file name used for vi tags
vi_tags = ".rstags"

# the file name used for emacs tags
emacs_tags = "rusty-tags.emacs"

# the name or path to the ctags executable, by default executables with names
# are searched in the following order: "ctags", "exuberant-ctags", "exctags", "universal-ctags", "uctags"
ctags_exe = ""

# options given to the ctags executable
ctags_options = ""
```

_NOTE:_ remember to add `*/.*tags` to your `.gitignore`

### TreeSitter [this](https://github.com/nvim-treesitter/nvim-treesitter)

I've set this one mainly to provide nice highlighting

Once installed, remember to add support for the languages you need.

for example:
```
:TSInstall go
```
