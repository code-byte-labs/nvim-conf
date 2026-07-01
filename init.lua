-- 入口文件，只负责加载其他模块

vim.cmd.source("~/.config/nvim/vimrc")

-- 基础设置
require("core.options")

-- 插件安装与加载 (vim.pack.add + 各插件 setup)
require("plugins")

-- 颜色主题与高亮覆盖 (依赖 onedarkpro，内部应用 colorscheme)
require("core.theme")

-- 快捷键映射 (依赖 telescope)
require("core.keymaps")

-- 自动命令 (依赖 telescope)
require("core.autocmds")
