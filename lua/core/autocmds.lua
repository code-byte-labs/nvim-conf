-- 自动命令 (augroup)

local telescope_builtin = require("telescope.builtin")

-- Treesitter 解析器映射
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

-- Telescope 的 prompt buffer 不需要按键级自动补全 ('autocomplete' 为 global-local)。
vim.api.nvim_create_autocmd("FileType", {
  pattern = "TelescopePrompt",
  callback = function(args)
    vim.bo[args.buf].autocomplete = false
  end,
})

-- LSP: 开启自动补全
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

-- LSP: 缓冲区局部快捷键
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
