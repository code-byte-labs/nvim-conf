local M = {}

local uv = vim.uv or vim.loop
local uri = require("core.jvm.uri")

local root_markers =
  { "gradlew", "mvnw", "build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts", "pom.xml", ".git" }

local function path_exists(path)
  return path and uv.fs_stat(path) ~= nil
end

local function same_path(a, b)
  if not a or not b or a == "" or b == "" then
    return false
  end
  return (uv.fs_realpath(a) or vim.fs.normalize(a)) == (uv.fs_realpath(b) or vim.fs.normalize(b))
end

local function read_lua_config(path)
  if not path_exists(path) then
    return {}
  end

  local chunk = loadfile(path)
  if type(chunk) ~= "function" then
    return {}
  end

  local ok, result = pcall(chunk)
  if ok and type(result) == "table" then
    return result
  end

  return {}
end

local function config_for_root(root_dir)
  local config = read_lua_config(vim.fn.stdpath("config") .. "/.kotlin-lsp.lua")
  if root_dir and root_dir ~= "" then
    local project_config = read_lua_config(vim.fs.joinpath(root_dir, ".kotlin-lsp.lua"))
    if project_config.jdk_for_symbol_resolution and not project_config.project_java_home then
      project_config.project_java_home = project_config.jdk_for_symbol_resolution
    end
    config = vim.tbl_deep_extend("force", config, project_config)
  end
  return config
end

local function uri_decode(value)
  local ok, decoded = pcall(vim.uri_decode, value)
  return ok and decoded or value
end

local function first_existing_path(paths)
  for _, path in ipairs(paths or {}) do
    if path_exists(path) then
      return path
    end
  end
end

local function find_existing_relative_path(base_dir, relative_paths)
  for _, relative_path in ipairs(relative_paths or {}) do
    local candidate = vim.fs.joinpath(base_dir, relative_path)
    if path_exists(candidate) then
      return candidate
    end
  end
end

local function normalize_archive_entry(path)
  local parts = vim.split(path, "/", { plain = true })
  if #parts > 1 then
    for i = 1, #parts - 1 do
      parts[i] = parts[i]:gsub("%.", "/")
    end
  end
  return table.concat(parts, "/")
end

local function parse_jdt_uri(jdt_uri)
  local container, raw_entry, raw_query = jdt_uri:match("^jdt://contents/([^/]+)/([^?]+)%?(.*)$")
  if not container or not raw_entry then
    return nil
  end

  local decoded_query = uri_decode(raw_query or ""):gsub("\\", "/")
  local normalized_query = decoded_query
  normalized_query = normalized_query:gsub("^=[^/]+", "")
  normalized_query = normalized_query:gsub("`.*$", "")
  normalized_query = normalized_query:gsub("/+", "/")

  return {
    container = container,
    raw_entry = raw_entry,
    query = decoded_query,
    normalized_query = normalized_query,
    is_jdk = not container:match("%.jar$"),
  }
end

local function read_archive_entry(archive, entries)
  if not path_exists(archive) then
    return nil
  end

  for _, entry in ipairs(entries) do
    local result = vim.system({ "unzip", "-p", archive, entry }, { text = true }):wait()
    if result.code == 0 and result.stdout ~= "" then
      return result.stdout:gsub("\r\n", "\n")
    end
  end
end

local function find_dependency_source_archive(info)
  local group_id = info.query:match("/maven%.groupId=/([^=]+)")
  local artifact_id = info.query:match("/maven%.artifactId=/([^=]+)")
  local version = info.query:match("/maven%.version=/([^=]+)")
  if not group_id or not artifact_id or not version then
    return nil
  end

  local archive_name = string.format("%s-%s-sources.jar", artifact_id, version)
  local home = vim.env.HOME
  if not home or home == "" then
    return nil
  end

  local m2_path = table.concat({
    home,
    ".m2/repository",
    group_id:gsub("%.", "/"),
    artifact_id,
    version,
    archive_name,
  }, "/")
  if path_exists(m2_path) then
    return m2_path
  end

  local gradle_dir = table.concat({
    home,
    ".gradle/caches/modules-2/files-2.1",
    group_id,
    artifact_id,
    version,
  }, "/")
  if path_exists(gradle_dir) then
    return vim.fs.find(archive_name, { path = gradle_dir, type = "file", limit = 1 })[1]
  end
end

local function find_jdk_source_archive(info)
  local user_config = config_for_root(nil)
  if type(user_config.find_jdk_source_archive) == "function" then
    local ok, archive = pcall(user_config.find_jdk_source_archive, info)
    if ok and type(archive) == "string" and path_exists(archive) then
      return archive
    end
  end

  local jrt_fs = info.normalized_query:match("(/.-/jrt%-fs%.jar)")
  if jrt_fs then
    local relative_paths = user_config.jdk_source_relative_paths or { "lib/src.zip", "src.zip" }
    local current = vim.fs.dirname(vim.fs.dirname(jrt_fs))
    local max_upward_levels = user_config.jdk_source_search_upward_levels or 2
    for _ = 0, max_upward_levels do
      local archive = find_existing_relative_path(current, relative_paths)
      if archive then
        return archive
      end
      local parent = vim.fs.dirname(current)
      if not parent or parent == current then
        break
      end
      current = parent
    end
  end

  local configured = first_existing_path(user_config.jdk_source_archives)
  if configured then
    return configured
  end

  for _, pattern in ipairs(user_config.jdk_source_patterns or {}) do
    local matches = vim.fn.glob(pattern, false, true)
    if #matches > 0 then
      table.sort(matches)
      return matches[1]
    end
  end
end

local function resolve_jdt_source(jdt_uri)
  local info = parse_jdt_uri(jdt_uri)
  if not info then
    return nil
  end

  local entry = normalize_archive_entry(info.raw_entry)
  local archive = info.is_jdk and find_jdk_source_archive(info) or find_dependency_source_archive(info)
  if not archive then
    return nil
  end

  local entries = { entry, info.raw_entry }
  if info.is_jdk then
    entries = {
      info.container .. "/" .. entry,
      info.container .. "/" .. info.raw_entry,
    }
  end

  local content = read_archive_entry(archive, entries)
  if not content then
    return nil
  end

  return {
    archive = archive,
    content = content,
  }
end

local function normalize_source_content(content)
  local lines = vim.split(content, "\n", { plain = true })
  while #lines > 0 and lines[1] == "" do
    table.remove(lines, 1)
  end
  return lines
end

local function is_decompiled_source(lines)
  return lines[1] and lines[1]:find("Source code is decompiled", 1, true) ~= nil
end

local function set_java_source_buffer(buf, content)
  local lines = normalize_source_content(content)
  vim.bo[buf].modifiable = true
  vim.bo[buf].swapfile = false
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].filetype = "java"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].modified = false
  return lines
end

function M.get_client(root_dir)
  for _, client in ipairs(vim.lsp.get_clients({ name = "jdtls" })) do
    if client.initialized and (not root_dir or same_path(client.root_dir, root_dir)) then
      return client
    end
  end
end

local function is_file_in_root(buf, root_dir)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" or not root_dir or root_dir == "" then
    return false
  end
  local real_name = uv.fs_realpath(name) or vim.fs.normalize(name)
  local real_root = uv.fs_realpath(root_dir) or vim.fs.normalize(root_dir)
  return real_name == real_root or vim.startswith(real_name, real_root .. "/")
end

function M.find_anchor_buf(root_dir)
  local current = vim.api.nvim_get_current_buf()
  if is_file_in_root(current, root_dir) then
    return current
  end

  local alt = vim.fn.bufnr("#", -1)
  if is_file_in_root(alt, root_dir) then
    return alt
  end

  for _, client in ipairs(vim.lsp.get_clients({ name = "kotlin_lsp" })) do
    if same_path(client.root_dir, root_dir) then
      for buf in pairs(client.attached_buffers or {}) do
        if vim.api.nvim_buf_is_valid(buf) and is_file_in_root(buf, root_dir) then
          return buf
        end
      end
    end
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and is_file_in_root(buf, root_dir) then
      return buf
    end
  end
end

local function attach_jdtls_client(buf)
  local client = M.get_client()
  if client then
    vim.lsp.buf_attach_client(buf, client.id)
    return client
  end
end

function M.setup_source_archive_patch()
  local jdtls = require("jdtls")
  if vim.g.jdtls_source_archive_patch then
    return
  end

  vim.g.jdtls_source_archive_patch = 1
  local original_open_classfile = jdtls.open_classfile

  ---@diagnostic disable-next-line: duplicate-set-field
  jdtls.open_classfile = function(buf, fname)
    if not uri.is_jdt(fname) then
      return original_open_classfile(buf, fname)
    end

    local source = resolve_jdt_source(fname)
    if not source then
      return original_open_classfile(buf, fname)
    end

    local client = attach_jdtls_client(buf)
    if not client then
      return original_open_classfile(buf, fname)
    end

    local lines = set_java_source_buffer(buf, source.content)
    if is_decompiled_source(lines) then
      return original_open_classfile(buf, fname)
    end

    vim.b[buf].jdtls_source_archive = source.archive
    if client:supports_method("textDocument/semanticTokens/full", buf) then
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          vim.lsp.semantic_tokens.force_refresh(buf)
        end
      end)
    end
  end
end

function M.root_dir(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  if name == "" then
    return nil
  end
  return vim.fs.root(buf or 0, root_markers) or vim.fs.dirname(name)
end

function M.build_config(root_dir)
  if not root_dir or root_dir == "" then
    return nil
  end

  local user_config = config_for_root(root_dir)
  local server_java_home = user_config.server_java_home or user_config.java_home
  if not server_java_home or server_java_home == "" then
    return nil
  end

  local java_executable = server_java_home .. "/bin/java"
  if not path_exists(java_executable) then
    java_executable = vim.fn.exepath("java")
    if java_executable == "" then
      return nil
    end
    server_java_home = vim.fn.fnamemodify(java_executable, ":h:h")
  end

  local runtime_name = user_config.runtime_name
  if not runtime_name or runtime_name == "" then
    return nil
  end

  local project_java_home = user_config.project_java_home or user_config.jdk_for_symbol_resolution or server_java_home
  if not path_exists(project_java_home) then
    project_java_home = server_java_home
  end

  local project_name = vim.fs.basename(root_dir)
  local workspace_dir = vim.fn.stdpath("data")
    .. "/jdtls-workspaces/"
    .. project_name
    .. "-"
    .. vim.fn.sha256(root_dir):sub(1, 8)

  return {
    name = "jdtls",
    cmd = { "jdtls", "--java-executable", java_executable, "-data", workspace_dir },
    root_dir = root_dir,
    settings = {
      java = {
        configuration = {
          runtimes = {
            {
              name = runtime_name,
              path = project_java_home,
              default = true,
            },
          },
        },
      },
    },
    _project_java_home = project_java_home,
  }
end

function M.start(root_dir)
  M.setup_source_archive_patch()
  if M.get_client(root_dir) then
    return true
  end
  local config = M.build_config(root_dir)
  if not config then
    return false
  end
  local anchor_buf = M.find_anchor_buf(root_dir)
  if not anchor_buf then
    return false
  end
  require("jdtls").start_or_attach(config, nil, { bufnr = anchor_buf })
  return true
end

function M.sync_project_jdk(buf, project_java_home)
  if not project_java_home or project_java_home == "" then
    return
  end

  local client = attach_jdtls_client(buf)
  if not client then
    return
  end

  require("jdtls.util").execute_command({
    command = "java.project.updateJdk",
    arguments = { vim.uri_from_bufnr(buf), project_java_home },
  }, function() end, buf)
end

function M.start_for_buffer(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local filename = vim.api.nvim_buf_get_name(buf)
  if filename == "" or uri.is_jdt(filename) or uri.is_zipfile(filename) or uri.is_jar(filename) or uri.is_jrt(filename) then
    M.setup_source_archive_patch()
    return false
  end

  local root_dir = M.root_dir(buf)
  local config = M.build_config(root_dir)
  if not config then
    M.setup_source_archive_patch()
    return false
  end

  M.setup_source_archive_patch()
  require("jdtls").start_or_attach(config)

  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(buf) then
      M.sync_project_jdk(buf, config._project_java_home)
    end
  end, 1000)

  return true
end

return M
