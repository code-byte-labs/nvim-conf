-- 自动命令 (augroup)

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

-- Modal/prompt buffer 不需要按键级自动补全 ('autocomplete' 为 global-local)。
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "snacks_picker_input", "snacks_input", "dapui_*", "dap-repl", "dap-float" },
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
    if client:supports_method("textDocument/foldingRange") then
      vim.wo.foldexpr = "v:lua.vim.lsp.foldexpr()"
    end
  end,
})

-- LSP: 缓冲区局部快捷键
vim.api.nvim_create_augroup("LspAttachGroup", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = "LspAttachGroup",
  callback = function(args)
    local bufnr = args.buf
    vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover Documentation" })
    vim.keymap.set("n", "gd", Snacks.picker.lsp_definitions, { buffer = bufnr, desc = "Go to Definition" })
    vim.keymap.set("n", "gr", Snacks.picker.lsp_references, { buffer = bufnr, desc = "Find References" })
    vim.keymap.set("n", "gi", Snacks.picker.lsp_implementations, { buffer = bufnr, desc = "Go to Implementation" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename Symbol" })
    vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code Action" })
  end,
})

-- Echo LSP work-done progress directly in the command area.
vim.api.nvim_create_autocmd("LspProgress", {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then
      return
    end

    local value = ev.data.params.value
    if type(value) ~= "table" then
      return
    end

    local text
    if value.kind == "end" or (type(value.percentage) == "number" and value.percentage >= 100) then
      text = ("%s loaded"):format(client.name)
    else
      local parts = {}
      parts[#parts + 1] = client.name
      if value.title and value.title ~= "" then
        parts[#parts + 1] = value.title
      end
      if value.message and value.message ~= "" then
        parts[#parts + 1] = value.message
      end
      if value.percentage then
        parts[#parts + 1] = string.format("(%d%%)", value.percentage)
      end
      text = #parts > 0 and table.concat(parts, " ") or ("%s working"):format(client.name)
    end

    vim.schedule(function()
      vim.api.nvim_echo({ { text } }, false, {})
    end)
  end,
})
