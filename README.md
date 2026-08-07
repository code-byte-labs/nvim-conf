## Prerequirement

这套配置不是零依赖，启动前至少需要把下面几类环境准备好：

- `Neovim >= 0.12`
  当前配置使用了 `vim.pack.add`、`vim.lsp.enable`、内建 `autocomplete` 和内建 Treesitter 接口，旧版本无法直接工作。
- `git` 和可访问 GitHub 的网络
  插件通过 `vim.pack.add` 从 GitHub 拉取，首次启动需要能正常 clone。
- 搜索/终端工具
  `Snacks.picker` 和日常终端工作流建议安装 `rg`、`fd`、`fzf`、`bat`、`jq`、`tree`、`lazygit`。

按当前配置启用的语言能力，还需要这些可执行文件在 `PATH` 中：

- JavaScript / TypeScript
  需要 `node`、`npm`、`tsc`、`biome`。其中 `tsc` 被当作 LSP 启动命令使用，`biome` 被 `conform.nvim` 用于 JS/TS/CSS/JSON 格式化。
- Python
  需要 `python3`、`uv`、`basedpyright`、`ruff`、`debugpy-adapter`。其中 `basedpyright` 和 `ruff` 用于 LSP / format / code action，`debugpy-adapter` 用于 DAP 调试。
- Go
  需要 `go`、`gopls`、`goimports`、`gofumpt`；如果要使用调试，还需要 `dlv`。
- Lua
  需要 `lua-language-server` 和 `stylua`。
- C / C++
  需要 `clangd`。
- Rust
  需要 `rust-analyzer`；如果还没装工具链，通常一并安装 `rustup`、`rust-src`。
- Dart
  配置里启用了 `dartls`，只有在你确实开发 Dart / Flutter 时才需要安装 `dart` / `flutter` 并确保 `dartls` 可用。

另外，这套配置没有使用 `nvim-treesitter` 插件，而是假定 parser 会手动放在 `~/.config/nvim/parser/` 下。若要让折叠、高亮和 `after/queries/*` 里的自定义查询真正生效，需要提前准备对应语言的 Treesitter parser。

下面脚本可运行在Linux/MacOS环境，并且使用 Homebrew + `nvm` + `uv`：

```bash
# 1. 安装 Homebrew（如果还没有）
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"' >> ~/.zshrc
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv zsh)"

# 2. 安装基础命令行工具和 Neovim
brew install neovim git ripgrep fd fzf bat jq tree lazygit xxd

# 3. 安装 Node.js（通过 nvm）
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.6/install.sh | bash
source ~/.zshrc
nvm install 24
nvm use 24

# 4. 安装常用语言运行时 / 工具链
brew install go lua-language-server stylua llvm cmake
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.zshrc
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"
rustup component add rust-analyzer
rustup component add rust-src

# 5. 安装 JS / TS 工具
npm install -g typescript
npm install -g @biomejs/biome

# 6. 安装 Python 工具
uv tool install basedpyright
uv tool install ruff@latest
uv tool install debugpy

# 7. 安装 Go 工具
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest
go install mvdan.cc/gofumpt@latest
go install github.com/go-delve/delve/cmd/dlv@latest
```

补充说明：

- Linux 剪贴板
  如果 `clipboard=unnamedplus` 不生效，再补装 `xclip` 或 `wl-clipboard`。这部分不在 `history.txt` 里，但在大多数 Linux 发行版上是系统剪贴板桥接所必需的。
- JavaScript / TypeScript 调试
  当前 DAP 配置把 `js-debug` 固定写在 `/opt/js-debug/src/dapDebugServer.js`。按照 `history.txt`，可以这样安装：

```bash
wget https://github.com/microsoft/vscode-js-debug/releases/download/v1.117.0/js-debug-dap-v1.117.0.tar.gz
tar -xvf js-debug-dap-v1.117.0.tar.gz
sudo mkdir -p /opt/js-debug
sudo cp -r js-debug/* /opt/js-debug/
```

- Dart / Flutter
  配置里启用了 `dartls`。如果不开发 Dart / Flutter，可以先忽略；如果需要，再单独安装 `dart` 或 Flutter SDK 并确认 `dartls` 在 `PATH` 中。
- Treesitter parser
  这套配置没有自动安装 parser。你需要自行把对应语言的 parser 放到 `~/.config/nvim/parser/`，否则自定义 query 虽然存在，但不会完整生效。

## 结构
~/.config/nvim/
├── init.lua                 # 入口文件，只负责加载其他模块
└── lua/
    ├── core/                # 核心配置文件夹
    │   ├── options.lua      # 基础设置 (vim.opt)
    │   ├── keymaps.lua      # 快捷键映射
    │   ├── theme.lua        # 颜色主题与高亮覆盖
    │   └── autocmds.lua     # 自动命令 (augroup)
    └── plugins.lua          # 插件安装与加载配置 (如使用 vim-plug)
