vim.cmd.source("~/.vimrc")
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

local onedark = require("onedarkpro.helpers")
local colors = onedark.get_colors("onedark")

vim.api.nvim_create_autocmd("ColorScheme", {
  pattern = "onedark",
  callback = function()
    vim.api.nvim_set_hl(0, "@lsp.type.namespace", { link = "Type" })
    vim.api.nvim_set_hl(0, "@lsp.type.member", { link = "@function" })
    vim.api.nvim_set_hl(0, "tsxCloseString", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "@parameter", { fg = colors.orange })
    vim.api.nvim_set_hl(0, "typescriptDefaultImportName", { fg = colors.red })
    vim.api.nvim_set_hl(0, "typescriptIdentifierName", { fg = colors.red })
    vim.api.nvim_set_hl(0, "typescriptImportBlock", { fg = colors.red })
    vim.api.nvim_set_hl(0, "typescriptBraces", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "@function.builtin", { fg = colors.cyan })
    vim.api.nvim_set_hl(0, "typescriptEndColons", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "typescriptObjectLabel", { link = "@property" })
    vim.api.nvim_set_hl(0, "typescriptFuncCallArg", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "typescriptArrowFunc", { link = "keyword" })
    vim.api.nvim_set_hl(0, "tsxTagName", { link = "Type" })
    vim.api.nvim_set_hl(0, "typescriptDecorator", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "htmlArg", { fg = colors.orange })
    vim.api.nvim_set_hl(0, "NvimTreeFolderIcon", {})
    vim.api.nvim_set_hl(0, "NvimTreeRootFolder", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "NvimTreeOpenedFolderName", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "NvimTreeFolderName", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "NvimTreeFolderArrowOpen", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "NvimTreeFolderArrowClosed", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "typescriptFuncTypeArrow", { link = "keyword" })
    vim.api.nvim_set_hl(0, "lessClass", { fg = colors.orange })
    vim.api.nvim_set_hl(0, "cssPositioningAttr", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "cssFunctionName", { fg = colors.cyan })
    vim.api.nvim_set_hl(0, "cssCustomProp", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "cssUnitDecorators", { fg = colors.red })
    vim.api.nvim_set_hl(0, "lessFunction", { fg = colors.cyan })
    vim.api.nvim_set_hl(0, "cssBraces", { fg = colors.orange })
    vim.api.nvim_set_hl(0, "typescriptCastKeyword", { link = "keyword" })
    vim.api.nvim_set_hl(0, "typescriptOperator", { link = "keyword" })
    vim.api.nvim_set_hl(0, "tsxAttrib", { fg = colors.orange })
    vim.api.nvim_set_hl(0, "@tag.tsx", { link = "Type" })
    vim.api.nvim_set_hl(0, "@type.tsx", { link = "@variable" })
    vim.api.nvim_set_hl(0, "@tag.builtin.tsx", { link = "@tag" })
    vim.api.nvim_set_hl(0, "@markup.heading", { fg = colors.fg })
    vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.typescriptreact", { fg = colors.yellow })
    vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.typescript", { fg = colors.yellow })
    vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.javascript", { fg = colors.yellow })
    vim.api.nvim_set_hl(0, "@tag.javascript", { link = "Type" })
    vim.api.nvim_set_hl(0, "@type.javascript", { link = "@variable" })
    vim.api.nvim_set_hl(0, "@tag.builtin.javascript", { link = "@tag" })
    vim.api.nvim_set_hl(0, "@lsp.typemod.variable.readonly.javascriptreact", { fg = colors.yellow })
    vim.api.nvim_set_hl(0, "@tag.attribute.javascript", { fg = colors.orange })
    vim.api.nvim_set_hl(0, "@punctuation.bracket.tsx", { link = "@punctuation.bracket" })
    vim.api.nvim_set_hl(0, "@punctuation.bracket.typescript", { link = "@punctuation.bracket" })
  end,
})

vim.cmd("colorscheme onedark")
local statusline = vim.o.statusline
statusline = statusline:gsub("%%f", "%%F", 1)
vim.o.statusline = statusline

-- Tabline: show only the file name (tail) per tab, not the full path.
function _G.tabline()
  local s = ""
  for i = 1, vim.fn.tabpagenr("$") do
    -- Active tab uses TabLineSel, others use TabLine.
    s = s .. (i == vim.fn.tabpagenr() and "%#TabLineSel#" or "%#TabLine#")
    s = s .. "%" .. i .. "T " -- clickable: switches to tab i

    local buflist = vim.fn.tabpagebuflist(i)
    local winnr = vim.fn.tabpagewinnr(i)
    local bufnr = buflist[winnr]
    local name = vim.fn.bufname(bufnr)
    name = (name == "") and "[No Name]" or vim.fn.fnamemodify(name, ":t")

    -- Modified indicator.
    local modified = vim.fn.getbufvar(bufnr, "&modified") == 1 and " [+]" or ""
    s = s .. name .. modified .. " "
  end
  s = s .. "%#TabLineFill#%T"
  return s
end

vim.o.tabline = "%!v:lua.tabline()"
vim.o.showtabline = 1 -- 1: only when 2+ tabs; set 2 to always show

-- Parsers are placed manually under parser/ (no nvim-treesitter plugin), so the
-- filetype -> language mappings must be registered explicitly. The tsx parser is
-- named "tsx" but the filetype is "typescriptreact"; likewise jsx maps to the
-- javascript parser. Without this, vim.treesitter.start errors with
-- "no parser for lang typescriptreact".
vim.treesitter.language.register("tsx", "typescriptreact")
vim.treesitter.language.register("javascript", "javascriptreact")

-- Built-in Treesitter does not auto-attach a highlighter in this config.
-- Start it on buffer filetype detection so custom captures are visible to :Inspect.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

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
local telescope_builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", telescope_builtin.find_files, { desc = "Telescope find files" })
vim.keymap.set("n", "<leader>fg", telescope_builtin.live_grep, { desc = "Telescope live grep" })
vim.keymap.set("n", "<leader>fb", telescope_builtin.buffers, { desc = "Telescope buffers" })
vim.keymap.set("n", "<leader>fr", telescope_builtin.oldfiles, { desc = "Telescope oldfiles" })
vim.o.autocomplete = true
vim.o.complete = ".,o,w"
vim.o.completeopt = "menu,menuone,noselect,popup"
-- vim.keymap.set('i', '<C-k>', vim.lsp.buf.signature_help, { desc = 'Signature Help' })
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", {}),
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end
    if client:supports_method("textDocument/completion") then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
  end,
})

vim.api.nvim_create_augroup("LspAttachGroup", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = "LspAttachGroup",
  callback = function(args)
    local bufnr = args.buf
    -- vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = 'Go to Definition' })
    vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, { desc = "Go to Definition" })
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover Documentation" })
    -- vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr, desc = 'Find References' })
    vim.keymap.set("n", "gr", telescope_builtin.lsp_references, { desc = "Find References" })
    -- vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = bufnr, desc = 'Go to Implementation' })
    vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, { desc = "Go to Implementation" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename Symbol" })
    -- code_action uses vim.ui.select, which telescope-ui-select renders via telescope.
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code Action" })
  end,
})

vim.lsp.enable({ "lua_ls", "ts_ls", "basedpyright", "gopls", "clangd", "angularls", "biome" })

require("conform").setup({
  formatters_by_ft = {
    go = { "gofumpt", "goimports" },
    lua = { "stylua" },
    css = { "biome-check" },
    json = { "biome-check" },
    jsonc = { "biome-check" },
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
