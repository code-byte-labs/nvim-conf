local M = {}

local uri = require("core.jvm.uri")

local function set_definition_keymap(bufnr)
  vim.keymap.set("n", "gd", require("core.goto").definition, { buffer = bufnr, desc = "Go to Definition" })
end

local function attach_clients(buf, name)
  for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
    pcall(vim.lsp.buf_attach_client, buf, client.id)
  end
end

local function attach_kotlin_virtual_buffers(client)
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(bufnr)
    if uri.is_jar(name) or uri.is_jrt(name) then
      vim.lsp.buf_attach_client(bufnr, client.id)
      set_definition_keymap(bufnr)
    end
  end
end

function M.setup(group)
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if not client then
        return
      end

      if client.name == "kotlin_lsp" then
        attach_kotlin_virtual_buffers(client)
      elseif client.name == "jdtls" and client:supports_method("textDocument/semanticTokens/full", args.buf) then
        vim.defer_fn(function()
          if vim.api.nvim_buf_is_valid(args.buf) and vim.bo[args.buf].filetype == "java" then
            vim.lsp.semantic_tokens.force_refresh(args.buf)
          end
        end, 300)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufEnter", {
    group = group,
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if uri.is_jar(name) or uri.is_jrt(name) then
        attach_clients(args.buf, "kotlin_lsp")
        set_definition_keymap(args.buf)
      elseif uri.is_jdt(name) or (uri.is_zipfile(name) and name:find("%.java$")) then
        set_definition_keymap(args.buf)
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      for _, client in ipairs(vim.lsp.get_clients({ name = "kotlin_lsp" })) do
        vim.lsp.stop_client(client.id, true)
      end
    end,
  })
end

return M
