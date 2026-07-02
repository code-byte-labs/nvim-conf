local M = {}

local source_semantic_ns = vim.api.nvim_create_namespace("kotlin_lsp_source_semantic_tokens")

local function zip_uri(zip, entry)
  return "zipfile://" .. zip .. "::" .. entry
end

local function clamp_range_to_zip(range, zip, entry)
  if not range then
    return
  end

  local line_count = #vim.fn.systemlist({ "unzip", "-p", zip, entry })
  range.start.line = math.max(0, math.min(range.start.line, line_count - 1))
  range["end"].line = math.max(0, math.min(range["end"].line, line_count - 1))
  return range
end

local function active_kotlin_client()
  return vim.iter(vim.lsp.get_clients({ name = "kotlin_lsp" })):find(function(client)
    return not client:is_stopped()
  end)
end

local function location_list(result)
  if not result then
    return {}
  end
  if result.uri or result.targetUri then
    return { result }
  end
  return result
end

local function show_locations(result, client)
  local locations = location_list(result)
  if #locations == 0 then
    vim.notify("No definition found", vim.log.levels.INFO)
  elseif #locations == 1 then
    vim.lsp.util.show_document(locations[1], client.offset_encoding or "utf-16", { reuse_win = true })
  else
    vim.fn.setqflist({}, " ", {
      title = "LSP definitions",
      items = vim.lsp.util.locations_to_items(locations, client.offset_encoding or "utf-16"),
    })
    vim.cmd.copen()
  end
end

local function token_modifiers(encoded, legend)
  local modifiers = {}
  local index = 1
  while encoded > 0 do
    if encoded % 2 == 1 then
      modifiers[#modifiers + 1] = legend[index]
    end
    encoded = math.floor(encoded / 2)
    index = index + 1
  end
  return modifiers
end

local function apply_source_semantic_tokens(bufnr, client, data)
  local provider = client.server_capabilities.semanticTokensProvider
  local legend = provider and provider.legend
  if not legend or not data then
    return
  end

  local ft = vim.bo[bufnr].filetype
  local priority = vim.hl.priorities.semantic_tokens
  local line
  local start_char = 0
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)

  vim.api.nvim_buf_clear_namespace(bufnr, source_semantic_ns, 0, -1)
  for i = 1, #data, 5 do
    local delta_line = data[i]
    line = line and line + delta_line or delta_line
    start_char = delta_line == 0 and start_char + data[i + 1] or data[i + 1]

    local token_type = legend.tokenTypes[data[i + 3] + 1]
    local text = lines[line + 1] or ""
    local start_col = vim.str_byteindex(text, client.offset_encoding or "utf-16", start_char, false)
    local end_col = vim.str_byteindex(text, client.offset_encoding or "utf-16", start_char + data[i + 2], false)

    if token_type and start_col and end_col then
      local opts = { end_col = end_col, priority = priority, hl_group = "@lsp.type." .. token_type .. "." .. ft }
      vim.api.nvim_buf_set_extmark(bufnr, source_semantic_ns, line, start_col, opts)
      for _, modifier in ipairs(token_modifiers(data[i + 4], legend.tokenModifiers)) do
        opts = { end_col = end_col, priority = priority + 1, hl_group = "@lsp.mod." .. modifier .. "." .. ft }
        vim.api.nvim_buf_set_extmark(bufnr, source_semantic_ns, line, start_col, opts)
        opts = {
          end_col = end_col,
          priority = priority + 2,
          hl_group = "@lsp.typemod." .. token_type .. "." .. modifier .. "." .. ft,
        }
        vim.api.nvim_buf_set_extmark(bufnr, source_semantic_ns, line, start_col, opts)
      end
    end
  end
end

local function request_source_semantic_tokens(bufnr)
  local uri = vim.b[bufnr].kotlin_lsp_uri
  local client = active_kotlin_client()
  if not uri or not uri:match("^jar://") or not client then
    return
  end

  client:request("textDocument/semanticTokens/full", { textDocument = { uri = uri } }, function(err, result)
    if err or not result then
      return
    end
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(bufnr) and vim.b[bufnr].kotlin_lsp_uri == uri then
        apply_source_semantic_tokens(bufnr, client, result.data)
      end
    end)
  end)
end

local function source_position_params(uri, encoding)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  return {
    textDocument = { uri = uri },
    position = {
      line = row - 1,
      character = vim.str_utfindex(line, encoding, col, false),
    },
  }
end

local function source_definition(telescope_builtin)
  local uri = vim.b.kotlin_lsp_uri
  local client = active_kotlin_client()
  if not uri or not client then
    return telescope_builtin.lsp_definitions()
  end

  client:request(
    "textDocument/definition",
    source_position_params(uri, client.offset_encoding or "utf-16"),
    function(err, result)
      if err then
        vim.notify(err.message or vim.inspect(err), vim.log.levels.ERROR)
        return
      end
      show_locations(result, client)
    end
  )
end

local function set_source_keymaps(bufnr, original_uri, telescope_builtin)
  vim.b[bufnr].kotlin_lsp_uri = original_uri
  vim.keymap.set("n", "gd", function()
    source_definition(telescope_builtin)
  end, { buffer = bufnr, desc = "Go to Definition" })
  request_source_semantic_tokens(bufnr)
end

function M.handle_location(location)
  local uri = location and (location.uri or location.targetUri)
  local jar, entry
  if uri then
    jar, entry = uri:match("^jar://(.-)!/(.+)$")
  end
  if not jar or not entry or not vim.endswith(entry, ".kt") then
    return
  end

  local translated = vim.deepcopy(location)
  local zip = vim.uri_to_fname("file://" .. jar)
  translated.uri = zip_uri(zip, entry)
  translated.range = clamp_range_to_zip(translated.range, zip, entry)
  return translated,
    function(bufnr, telescope_builtin)
      vim.bo[bufnr].filetype = "kotlin"
      pcall(vim.treesitter.start, bufnr)
      set_source_keymaps(bufnr, uri, telescope_builtin)
    end
end

return M
