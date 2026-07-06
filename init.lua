-- 入口文件，只负责加载其他模块

vim.cmd.source("~/.config/nvim/vimrc")

-- 基础设置
require("core.options")

-- 插件安装与加载 (vim.pack.add + 各插件 setup)
require("plugins")

-- 颜色主题与高亮覆盖 (依赖 onedarkpro，内部应用 colorscheme)
require("core.theme")

-- 快捷键映射 (依赖插件)
require("core.keymaps")

-- 自动命令
require("core.autocmds")

-- DAP 调试配置 (Go / Python / JS / Chrome)
require("core.dap")
