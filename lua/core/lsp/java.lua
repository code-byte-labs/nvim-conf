local M = {}

local java17_home = "/Users/bytedance/Library/Java/JavaVirtualMachines/azul-17.0.19/Contents/Home"

local function extracted_source_path(zip, entry)
  local path = vim.fn.stdpath("cache") .. "/java-source/" .. vim.fn.sha256(zip) .. "/" .. entry
  if vim.fn.filereadable(path) == 0 then
    vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
    vim.fn.writefile(vim.fn.systemlist({ "unzip", "-p", zip, entry }), path)
  end
  return path
end

local function clamp_range_to_file(range, path)
  if not range then
    return
  end

  local line_count = #vim.fn.readfile(path)
  range.start.line = math.max(0, math.min(range.start.line, line_count - 1))
  range["end"].line = math.max(0, math.min(range["end"].line, line_count - 1))
  return range
end

local function source_zip_for(entry, java_home)
  local candidates = {}
  local seen = {}

  local function add(path)
    if path and path ~= "" and vim.fn.filereadable(path) == 1 and not seen[path] then
      table.insert(candidates, path)
      seen[path] = true
    end
  end

  add(java_home and (java_home .. "/lib/src.zip"))
  add(vim.env.JAVA_HOME and (vim.env.JAVA_HOME .. "/lib/src.zip"))
  vim.list_extend(
    candidates,
    vim.fn.glob("~/Library/Java/JavaVirtualMachines/*/Contents/Home/lib/src.zip", false, true)
  )
  vim.list_extend(candidates, vim.fn.glob("/Library/Java/JavaVirtualMachines/*/Contents/Home/lib/src.zip", false, true))

  for _, zip in ipairs(candidates) do
    vim.fn.system({ "unzip", "-l", zip, entry })
    if vim.v.shell_error == 0 then
      return zip
    end
  end
end

local function zip_has_entry(zip, entry)
  vim.fn.system({ "unzip", "-l", zip, entry })
  return vim.v.shell_error == 0
end

local function java_class_range(zip, entry, class_name)
  local lines = vim.fn.systemlist({ "unzip", "-p", zip, entry })
  if vim.v.shell_error ~= 0 then
    return
  end

  local escaped_name = class_name:gsub("([^%w_])", "%%%1")
  for i, line in ipairs(lines) do
    if
      line:match("%f[%w_]class%s+" .. escaped_name .. "%f[^%w_]")
      or line:match("%f[%w_]interface%s+" .. escaped_name .. "%f[^%w_]")
      or line:match("%f[%w_]enum%s+" .. escaped_name .. "%f[^%w_]")
      or line:match("%f[%w_]record%s+" .. escaped_name .. "%f[^%w_]")
      or line:match("@interface%s+" .. escaped_name .. "%f[^%w_]")
    then
      local col = (line:find(class_name, 1, true) or 1) - 1
      return {
        start = { line = i - 1, character = col },
        ["end"] = { line = i - 1, character = col + #class_name },
      }
    end
  end
end

local function java_member_range(zip, entry, member_name, is_method, arg_type)
  local lines = vim.fn.systemlist({ "unzip", "-p", zip, entry })
  if vim.v.shell_error ~= 0 then
    return
  end

  local function find_line(pattern)
    for i, line in ipairs(lines) do
      if not line:match("^%s*[%*/]") then
        local col = line:find(pattern)
        if col then
          return i, (line:find(member_name, 1, true) or col) - 1
        end
      end
    end
  end

  local i, col
  if is_method then
    if arg_type then
      i, col = find_line("%f[%w_]" .. member_name .. "%s*%([^)]*" .. arg_type:gsub("([^%w_])", "%%%1"))
    end
    if not i then
      i, col = find_line("%f[%w_]" .. member_name .. "%s*%(")
    end
  else
    i, col = find_line("%f[%w_]" .. member_name .. "%f[^%w_]%s*[=;]")
  end
  if not i then
    i, col = find_line(member_name)
  end
  if i then
    return {
      start = { line = i - 1, character = col },
      ["end"] = { line = i - 1, character = col + #member_name },
    }
  end
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

local function hover_value_and_docs(contents)
  if type(contents) == "string" then
    return contents, contents
  end

  local value = contents.value or contents[1] and contents[1].value
  local docs = {}
  for _, item in ipairs(contents) do
    if type(item) == "string" then
      docs[#docs + 1] = item
    end
  end
  return value, table.concat(docs, "\n")
end

local function java_source_definition()
  local word = vim.fn.expand("<cword>")
  local zip = vim.b.source_zip
  local entry = vim.b.source_entry
  if word == "" or not zip or not entry then
    return
  end

  local module, package_path = entry:match("^([^/]+)/(.+)/[^/]+%.java$")
  if not module then
    return
  end

  local candidates = {}
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    local import_path = line:match("^%s*import%s+([%w_.]+%." .. word .. ")%s*;")
    if import_path then
      table.insert(candidates, module .. "/" .. import_path:gsub("%.", "/") .. ".java")
    end
  end
  table.insert(candidates, module .. "/" .. package_path .. "/" .. word .. ".java")
  table.insert(candidates, module .. "/java/lang/" .. word .. ".java")

  for _, candidate in ipairs(candidates) do
    if zip_has_entry(zip, candidate) then
      vim.lsp.util.show_document({
        uri = vim.uri_from_fname(extracted_source_path(zip, candidate)),
        range = java_class_range(zip, candidate, word),
      }, "utf-16", { reuse_win = true })
      return
    end
  end

  vim.notify("No source found for " .. word, vim.log.levels.INFO)
end

local function jdk_source_definition_from_hover(client, params)
  client:request("textDocument/hover", params, function(err, result)
    if err or not result or not result.contents then
      vim.notify("No definition found", vim.log.levels.INFO)
      return
    end

    local value, docs = hover_value_and_docs(result.contents)
    local class_fqn, member_name = value and value:match("([%w_$.]+)%.([%w_]+)%s*%(")
    local is_method = member_name ~= nil
    local arg_type = value and value:match("%.[%w_]+%(([%w_$.%[%]]+)%s+[%w_]+%)")
    local field_type = value and value:match("^([%w_$.]+)%s+" .. vim.fn.expand("<cword>") .. "$")
    local is_class = false
    local line = vim.api.nvim_get_current_line()
    local prefix = line:sub(1, vim.api.nvim_win_get_cursor(0)[2] + 1):gsub("[%w_]*$", "")
    local qualifier = prefix:match("([%w_]+)%s*%.$")
    if not class_fqn then
      class_fqn = value and value:match("^([%w_$.]+)$")
      is_class = class_fqn ~= nil
    end
    class_fqn = class_fqn or field_type or docs:match("class%s+`?([%w_$.]+)`?")
    member_name = not is_class and vim.fn.expand("<cword>") or nil

    if not class_fqn then
      vim.notify("No definition found", vim.log.levels.INFO)
      return
    end

    if not class_fqn:find(".", 1, true) then
      if field_type and qualifier then
        class_fqn = qualifier == "System" and "java.lang.System" or qualifier
      else
        class_fqn = field_type and "java.io." .. class_fqn or "java.lang." .. class_fqn
      end
    end

    local source_entry = "java.base/" .. class_fqn:gsub("%$.*$", ""):gsub("%.", "/") .. ".java"
    local zip = source_zip_for(source_entry, java17_home)
    if not zip then
      vim.notify("No source found for " .. class_fqn, vim.log.levels.INFO)
      return
    end

    local ok = vim.lsp.util.show_document({
      uri = vim.uri_from_fname(extracted_source_path(zip, source_entry)),
      range = member_name and java_member_range(zip, source_entry, member_name, is_method, arg_type)
        or java_class_range(zip, source_entry, class_fqn:match("[^.$]+$")),
    }, "utf-16", { reuse_win = true })
    if ok then
      local bufnr = vim.api.nvim_get_current_buf()
      vim.bo[bufnr].filetype = "java"
      vim.b[bufnr].source_zip = zip
      vim.b[bufnr].source_entry = source_entry
      vim.keymap.set("n", "gd", java_source_definition, { buffer = bufnr, desc = "Go to Definition" })
    end
  end)
end

function M.definition(telescope_builtin)
  local client = vim.lsp.get_clients({ bufnr = 0, name = "jdtls" })[1]
  if not client then
    return telescope_builtin.lsp_definitions()
  end

  local params = vim.lsp.util.make_position_params(0, client.offset_encoding or "utf-16")
  client:request("textDocument/definition", params, function(err, result)
    if err then
      vim.notify(err.message or vim.inspect(err), vim.log.levels.ERROR)
      return
    end
    if #location_list(result) > 0 then
      show_locations(result, client)
      return
    end
    jdk_source_definition_from_hover(client, params)
  end)
end

function M.handle_location(location)
  local uri = location and (location.uri or location.targetUri)
  if not uri then
    return
  end

  local source_zip
  local source_entry
  local jar, entry = uri:match("^jar://(.-)!/(.+)$")
  if jar and vim.endswith(entry, ".java") then
    source_zip = vim.uri_to_fname("file://" .. jar)
    source_entry = entry
  else
    local java_home, module, class_path = uri:match("^jrt://(.-)!/modules/([^/]+)/(.+)%.class$")
    if java_home then
      local source_path = class_path:gsub("%$.*$", "")
      source_entry = module .. "/" .. source_path .. ".java"
      source_zip = source_zip_for(source_entry, vim.uri_to_fname("file://" .. java_home))
    end
  end

  if not source_zip then
    return
  end

  local path = extracted_source_path(source_zip, source_entry)
  local translated = vim.deepcopy(location)
  translated.uri = vim.uri_from_fname(path)
  translated.range = clamp_range_to_file(translated.range, path)
  if uri:match("^jrt://") then
    translated.range = java_class_range(source_zip, source_entry, vim.fn.fnamemodify(source_entry, ":t:r"))
      or translated.range
  end

  return translated,
    function(bufnr)
      vim.bo[bufnr].filetype = "java"
      vim.b[bufnr].source_zip = source_zip
      vim.b[bufnr].source_entry = source_entry
      vim.keymap.set("n", "gd", java_source_definition, { buffer = bufnr, desc = "Go to Definition" })
    end
end

return M
