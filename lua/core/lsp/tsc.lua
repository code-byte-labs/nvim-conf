local M = {}

local function is_bracket_text(text)
  return text ~= nil and text:sub(1, 1) == "["
end

local function text_edit_text(item)
  local te = item.textEdit
  if not te then
    return nil
  end
  if te.range or te.insert then
    return te.newText
  end
  return nil
end

local function text_edit_start(item, lnum)
  local te = item.textEdit
  if not te then
    return nil
  end
  if te.range and te.range.start.line == lnum then
    return te.range.start
  end
  if te.insert and te.insert.start.line == lnum then
    return te.insert.start
  end
  return nil
end

function M.setup()
  local completion = vim.lsp.completion
  if completion._tsc_boundary_patch then
    return
  end
  completion._tsc_boundary_patch = true

  local convert_results = completion._convert_results

  completion._convert_results = function(line, lnum, cursor_col, client_id, ...)
    local client = vim.lsp.get_client_by_id(client_id)
    if client and client.name == "tsc" then
      local args = { ... }
      local word_boundary = args[1]
      local result = args[3]
      local encoding = args[4]
      local items = result and result.items
      if items then
        local dot_byte, dot_char = nil, nil
        for _, item in ipairs(items) do
          local start = text_edit_start(item, lnum)
          if start and is_bracket_text(text_edit_text(item)) then
            local sb = vim.str_byteindex(line, encoding, start.character, false)
            if sb < word_boundary and (not dot_byte or sb < dot_byte) then
              dot_byte, dot_char = sb, start.character
            end
          end
        end

        if dot_byte then
          -- 成员上下文：tsc 把 `o["foo bar"]` 这类键表示成 textEdit 起始在 `.` 上的
          -- 方括号条目（`["foo bar"]`），会把 server_start_boundary 拖回 `.`，
          -- 导致 `o.` 补 `Symbol` 变成 `oSymbol`、`o.f` 前缀变成 `.f`。
          -- 这里把边界强制回 word_boundary，并给这些条目补一段 additionalTextEdits
          -- 在选中时删除点号，两全：
          --   - 普通成员照常插入（`o.f` -> `o.foo`）；
          --   - 字符串键成员也可用（`o.` -> `o["foo bar"]`）。
          args[2] = word_boundary
          local wb_char = vim.str_utfindex(line, encoding, word_boundary)
          for _, item in ipairs(items) do
            local start = text_edit_start(item, lnum)
            if
              start
              and is_bracket_text(text_edit_text(item))
              and vim.str_byteindex(line, encoding, start.character, false) < word_boundary
            then
              local delete = {
                range = {
                  start = { line = lnum, character = start.character },
                  ["end"] = { line = lnum, character = wb_char },
                },
                newText = "",
              }
              item.additionalTextEdits = vim.list_extend(
                { delete },
                item.additionalTextEdits or {}
              )
            end
          end
          result = vim.tbl_extend("force", result, { items = items })
          args[3] = result
        end
      end
      return convert_results(line, lnum, cursor_col, client_id, unpack(args, 1, 4))
    end

    return convert_results(line, lnum, cursor_col, client_id, ...)
  end
end

return M
