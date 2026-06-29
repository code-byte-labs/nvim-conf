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
