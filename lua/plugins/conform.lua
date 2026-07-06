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
    timeout_ms = 1000,
    lsp_format = "fallback",
  },
})
