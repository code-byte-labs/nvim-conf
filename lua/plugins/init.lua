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
  { src = "https://github.com/windwp/nvim-ts-autotag" },
})

require("plugins.nvim-tree")
require("plugins.snacks")
require("plugins.lsp")
require("plugins.conform")
require("plugins.autotag")
