local M = {}

local handlers = {
  require("core.jvm.goto"),
}

local function telescope_definition()
  require("telescope.builtin").lsp_definitions()
end

local function has_handler(bufnr)
  for _, handler in ipairs(handlers) do
    if handler.can_handle_buffer and handler.can_handle_buffer(bufnr) then
      return true
    end
  end
  return false
end

function M.set_cursor(win, line, col)
  local buf = vim.api.nvim_win_get_buf(win)
  local line_count = vim.api.nvim_buf_line_count(buf)
  line = math.max(1, math.min(line, line_count))
  local text = vim.api.nvim_buf_get_lines(buf, line - 1, line, false)[1] or ""
  col = math.max(0, math.min(col, #text))
  vim.api.nvim_win_set_cursor(win, { line, col })
end

function M.open_uri_location(uri, range, adjust)
  if not uri then
    return
  end

  vim.schedule(function()
    local buf = vim.uri_to_bufnr(uri)
    vim.fn.bufload(buf)
    vim.api.nvim_win_set_buf(0, buf)
    local line = range and (range.start.line + 1) or 1
    local col = range and range.start.character or 0
    if adjust then
      line, col = adjust(buf, line, col)
    end
    M.set_cursor(0, line, col)
  end)
end

function M.open_location(uri, range, adjust)
  if not uri then
    return
  end

  local location_uri = uri
  for _, handler in ipairs(handlers) do
    if handler.open_location and handler.open_location(location_uri, range, adjust, M) then
      return
    end
  end
  M.open_uri_location(location_uri, range, adjust)
end

function M.definition()
  if not has_handler(0) then
    telescope_definition()
    return
  end

  for _, handler in ipairs(handlers) do
    if handler.before_definition and handler.before_definition(M) then
      return
    end
  end

  local params = vim.lsp.util.make_position_params(0, "utf-16")
  vim.lsp.buf_request(0, "textDocument/definition", params, function(err, result, ctx)
    if err or not result then
      return
    end
    local loc = vim.islist(result) and result[1] or result
    if not loc then
      return
    end
    local uri = loc.uri or loc.targetUri
    local range = loc.range or loc.targetSelectionRange or loc.targetRange
    if not uri then
      return
    end

    for _, handler in ipairs(handlers) do
      if handler.handle_location and handler.handle_location(uri, range, M) then
        return
      end
    end

    vim.schedule(function()
      vim.lsp.util.show_document(loc, "utf-16", { focus = true })
    end)
  end)
end

return M
