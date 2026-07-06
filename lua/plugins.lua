-- 插件安装与加载配置 (使用内建 vim.pack)

vim.pack.add({
  { src = "https://github.com/olimorris/onedarkpro.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/stevearc/conform.nvim" },
  { src = "https://github.com/sindrets/diffview.nvim" },
  { src = "https://github.com/m00qek/baleia.nvim" },
  { src = "https://github.com/neogitorg/neogit" },
  { src = "https://github.com/rcarriga/nvim-dap-ui" },
  { src = "https://github.com/nvim-neotest/nvim-nio" },
  { src = "https://github.com/mfussenegger/nvim-dap" },
  { src = "https://github.com/theHamsta/nvim-dap-virtual-text" },
  { src = "https://github.com/leoluz/nvim-dap-go" },
  { src = "https://github.com/folke/snacks.nvim" },
})

-- nvim-tree (先禁用 netrw)
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
require("nvim-tree").setup({
  renderer = {
    icons = {
      show = {
        git = false, -- 设为 false 即可隐藏 Git 状态图标
      },
    },
  },
})

-- snacks
require("snacks").setup({
  input = {
    win = {
      row = false,
      col = false,
    },
  },
  picker = {},
})
Snacks.input.enable()
vim.ui.select = Snacks.picker.select

-- LSP servers
vim.lsp.enable({
  "lua_ls",
  "ts_ls",
  "basedpyright",
  "ruff",
  "gopls",
  "clangd",
  "angularls",
  "biome",
  "rust_analyzer",
})

-- conform (格式化)
require("conform").setup({
  formatters_by_ft = {
    go = { "gofumpt", "goimports" },
    lua = { "stylua" },
    css = { "biome" },
    json = { "biome" },
    jsonc = { "biome" },
    python = { "ruff", "ruff_format", "ruff_organize_imports" },
    javascript = { "biome-check" },
    typescript = { "biome-check" },
    javascriptreact = { "biome-check" },
    typescriptreact = { "biome-check" },
  },
  formatters = {
    stylua = {
      prepend_args = { "--column-width", "120", "--indent-type", "Spaces", "--indent-width", "2" },
    },
    biome = {
      args = {
        "format",
        "--line-width",
        "120",
        "--indent-style",
        "space",
        "--indent-width",
        "2",
        "--stdin-file-path",
        "$FILENAME",
      },
    },
  },
  format_on_save = {
    -- These options will be passed to conform.format()
    timeout_ms = 1000,
    lsp_format = "fallback",
  },
})
