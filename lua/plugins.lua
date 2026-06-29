-- 插件安装与加载配置 (使用内建 vim.pack)

vim.pack.add({
  { src = "https://github.com/olimorris/onedarkpro.nvim" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-tree/nvim-tree.lua" },
  { src = "https://github.com/nvim-lua/plenary.nvim" },
  { src = "https://github.com/nvim-telescope/telescope.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-fzf-native.nvim" },
  { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/stevearc/conform.nvim" },
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

-- telescope
-- You dont need to set any of these options. These are the default ones. Only
-- the loading is important
require("telescope").setup({
  extensions = {
    fzf = {
      fuzzy = true, -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true, -- override the file sorter
      case_mode = "smart_case", -- or "ignore_case" or "respect_case"
      -- the default case_mode is "smart_case"
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown({}),
    },
  },
})
-- To get fzf loaded and working with telescope, you need to call
-- load_extension, somewhere after setup function:
require("telescope").load_extension("fzf")
-- ui-select routes vim.ui.select (used by vim.lsp.buf.code_action) through telescope.
require("telescope").load_extension("ui-select")

-- LSP servers
vim.lsp.enable({ "lua_ls", "ts_ls", "basedpyright", "gopls", "clangd", "angularls", "biome", "rust_analyzer" })

-- conform (格式化)
require("conform").setup({
  formatters_by_ft = {
    go = { "gofumpt", "goimports" },
    lua = { "stylua" },
    css = { "biome" },
    json = { "biome" },
    jsonc = { "biome" },
    python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
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
