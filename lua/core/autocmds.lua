-- 自动命令 (augroup)

local telescope_builtin = require("telescope.builtin")
local java_lsp = require("core.lsp.java")
local kotlin_lsp = require("core.lsp.kotlin")

do
  local show_document = vim.lsp.util.show_document

  vim.lsp.util.show_document = function(location, position_encoding, opts)
    local original_location = location
    local on_open
    location, on_open = java_lsp.handle_location(location)
    if not location then
      location, on_open = kotlin_lsp.handle_location(original_location)
    end
    location = location or original_location
    local ok = show_document(location, position_encoding, opts)
    if ok and on_open then
      on_open(vim.api.nvim_get_current_buf(), telescope_builtin)
    end
    return ok
  end
end

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
    if vim.b[bufnr].source_zip or vim.b[bufnr].kotlin_lsp_uri then
      return
    end
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local definition = client
        and client.name == "jdtls"
        and function()
          java_lsp.definition(telescope_builtin)
        end
      or telescope_builtin.lsp_definitions
    vim.keymap.set("n", "gd", definition, { buffer = bufnr, desc = "Go to Definition" })
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover Documentation" })
    vim.keymap.set("n", "gr", telescope_builtin.lsp_references, { buffer = bufnr, desc = "Find References" })
    vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, { buffer = bufnr, desc = "Go to Implementation" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename Symbol" })
    -- code_action uses vim.ui.select, which telescope-ui-select renders via telescope.
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code Action" })
  end,
})
