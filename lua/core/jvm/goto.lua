-- 库源码跳转：
--   1. Kotlin/普通依赖源码沿用 jar/zipfile 打开。
--   2. JDK/Java 符号交给 jdtls；jdtls 未启动时直接按项目 root 启动。

local M = {}

local uri = require("core.jvm.uri")

local root_markers =
  { "gradlew", "mvnw", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", "pom.xml", ".git" }

function M.can_handle_buffer(bufnr)
  local ft = vim.bo[bufnr].filetype
  if ft == "java" or ft == "kotlin" then
    return true
  end

  local name = vim.api.nvim_buf_get_name(bufnr)
  return uri.is_jar(name) or uri.is_jrt(name) or uri.is_jdt(name) or (uri.is_zipfile(name) and name:find("%.java$") ~= nil)
end

local function get_jdtls_client(root_dir)
  return require("core.jvm.jdtls").get_client(root_dir)
end

local function attached_root(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if (client.name == "kotlin_lsp" or client.name == "jdtls") and client.root_dir and client.root_dir ~= "" then
      return client.root_dir
    end
  end
end

local function current_root_dir()
  local root = attached_root(vim.api.nvim_get_current_buf()) or attached_root(vim.fn.bufnr("#", -1))
  if root then
    return root
  end

  local name = vim.api.nvim_buf_get_name(0)
  if name ~= "" and not (uri.is_jar(name) or uri.is_jrt(name) or uri.is_jdt(name) or uri.is_zipfile(name)) then
    root = vim.fs.root(name, root_markers)
    if root then
      return root
    end
  end

  for _, client in ipairs(vim.lsp.get_clients({ name = "kotlin_lsp" })) do
    if client.root_dir and client.root_dir ~= "" then
      return client.root_dir
    end
  end

  local cwd = vim.uv.cwd()
  return cwd and vim.fs.root(cwd, root_markers) or nil
end

local function start_jdtls(root_dir)
  root_dir = root_dir or current_root_dir()
  if not root_dir or root_dir == "" then
    return false
  end
  return require("core.jvm.jdtls").start(root_dir)
end

local function with_jdtls(callback)
  local root_dir = current_root_dir()
  local client = get_jdtls_client(root_dir)
  if client then
    callback(client)
    return true
  end
  if not start_jdtls(root_dir) then
    return false
  end
  local deadline = vim.uv.now() + 20000
  local function wait()
    local ready = get_jdtls_client(root_dir)
    if ready then
      callback(ready)
    elseif vim.uv.now() < deadline then
      vim.defer_fn(wait, 300)
    end
  end
  wait()
  return true
end

local function attach_clients(buf, name)
  for _, client in ipairs(vim.lsp.get_clients({ name = name })) do
    pcall(vim.lsp.buf_attach_client, buf, client.id)
  end
end

local function attach_virtual_buffer_clients()
  local buf = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if uri.is_jar(name) or uri.is_jrt(name) then
    attach_clients(buf, "kotlin_lsp")
  elseif uri.is_jdt(name) then
    attach_clients(buf, "jdtls")
  end
end

local function class_declaration_adjust(name)
  return function(buf, line, col)
    if line > 1 then
      return line, col
    end

    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local kinds = { "class", "interface", "enum", "record" }
    for i, text in ipairs(lines) do
      if not text:match("^%s*[%*/]") then
        for _, kw in ipairs(kinds) do
          local s = text:find("%f[%w]" .. kw .. "%s+" .. vim.pesc(name) .. "%f[%W]")
          if s then
            local name_start = text:find(vim.pesc(name), s)
            return i, (name_start or s) - 1
          end
        end
      end
    end

    return line, col
  end
end

local function route_via_jdtls(target, gateway)
  if not target then
    return false
  end

  -- workspace/symbol 只按简单名匹配；用 pkg + class 精确挑选。
  -- 内部类 Outer$Inner：符号名通常是 Inner，源码文件是 Outer.java，故用最外层类名查/配。
  local outer = target.class:match("^([^%$]+)")
  local want = "/" .. target.pkg .. "/" .. outer .. ".java"
  local query = target.symbol or outer

  return with_jdtls(function(client)
    client:request("workspace/symbol", { query = query }, function(err, result)
      if err or not result or #result == 0 then
        return
      end
      local decode = function(s)
        local ok, d = pcall(vim.uri_decode, s)
        return ok and d or s
      end
      local chosen
      for _, sym in ipairs(result) do
        local location_uri = sym.location and sym.location.uri
        local name = sym.name or ""
        local matched_symbol = not target.symbol or name == target.symbol or name:find(target.symbol, 1, true)
        if matched_symbol and location_uri and decode(location_uri):find(want, 1, true) then
          chosen = sym.location
          break
        end
      end
      if not chosen then
        return
      end
      gateway.open_location(chosen.uri, chosen.range, class_declaration_adjust(outer))
    end)
  end)
end

local function find_current_package(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, math.min(80, vim.api.nvim_buf_line_count(buf)), false)
  for _, line in ipairs(lines) do
    local pkg = line:match("^%s*package%s+([%w_.]+)%s*;?")
    if pkg then
      return pkg
    end
  end
end

local function archive_has_entry(archive, entry)
  if vim.fn.executable("unzip") ~= 1 then
    return false
  end
  return vim.system({ "unzip", "-Z1", archive, entry }):wait().code == 0
end

local function goto_from_zip_source(gateway)
  local info = uri.parse_zip_source_uri(vim.api.nvim_buf_get_name(0))
  if not info then
    return false
  end

  local word = vim.fn.expand("<cword>")
  if word == "" or not word:match("^%u") then
    return false
  end

  local pkg = find_current_package(0)
  if not pkg then
    return false
  end

  if route_via_jdtls({ pkg = pkg, class = word }, gateway) then
    return true
  end

  local module = info.entry:match("^([^/]+)/")
  local entry = (module and (module .. "/") or "") .. pkg:gsub("%.", "/") .. "/" .. word .. ".java"
  if archive_has_entry(info.archive, entry) then
    gateway.open_location("zipfile://" .. info.archive .. "::" .. entry)
    return true
  end

  return false
end

function M.before_definition(gateway)
  attach_virtual_buffer_clients()
  return goto_from_zip_source(gateway)
end

function M.open_location(location_uri, range, adjust, gateway)
  if not uri.is_jdt(location_uri) then
    return false
  end

  vim.schedule(function()
    vim.cmd.edit(vim.fn.fnameescape(location_uri))
    local buf = vim.api.nvim_get_current_buf()
    local line = range and (range.start.line + 1) or 1
    local col = range and range.start.character or 0
    if adjust then
      line, col = adjust(buf, line, col)
    end
    gateway.set_cursor(0, line, col)
  end)
  return true
end

function M.handle_location(location_uri, range, gateway)
  local jrt_class = uri.parse_jrt_class_uri(location_uri)
  if jrt_class and route_via_jdtls({
    pkg = jrt_class.pkg,
    class = jrt_class.class,
  }, gateway) then
    return true
  end

  -- kotlin-lsp 对 JDK 源码返回 jar://...src.zip!...java；JDK Java 源码转给 jdtls，
  -- 其他源码 jar 仍转给 zipPlugin。
  if uri.is_jar(location_uri) then
    local source = uri.parse_jar_source_uri(location_uri)
    if source then
      local jdk_source = uri.parse_jdk_source_entry(source)
      if jdk_source and route_via_jdtls(jdk_source, gateway) then
        return true
      end
      gateway.open_location(source.uri, range)
      return true
    end
  end

  if uri.is_jar(location_uri) or uri.is_jrt(location_uri) or uri.is_jdt(location_uri) or uri.is_zipfile(location_uri) then
    gateway.open_location(location_uri, range)
    return true
  end

  return false
end

return M
