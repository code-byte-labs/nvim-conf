local M = {}

function M.is_jar(uri)
  return uri and uri:find("^jar://") ~= nil
end

function M.is_jrt(uri)
  return uri and uri:find("^jrt://") ~= nil
end

function M.is_jdt(uri)
  return uri and uri:find("^jdt://") ~= nil
end

function M.is_zipfile(uri)
  return uri and uri:find("^zipfile://") ~= nil
end

function M.parse_jar_source_uri(uri)
  if not M.is_jar(uri) then
    return nil
  end
  local archive, entry = uri:match("^jar://(.-)!/(.+%.java)$")
  if not archive or not entry then
    return nil
  end
  return {
    archive = archive,
    entry = entry,
    uri = "zipfile://" .. archive .. "::" .. entry,
  }
end

function M.parse_zip_source_uri(uri)
  if not M.is_zipfile(uri) then
    return nil
  end
  local archive, entry = uri:match("^zipfile://(.-)::(.+%.java)$")
  if not archive or not entry then
    return nil
  end
  return {
    archive = archive,
    entry = entry,
  }
end

function M.parse_jdk_source_entry(source)
  if not source or not source.archive:match("/src%.zip$") then
    return nil
  end
  local _, pkg_path, class = source.entry:match("^([^/]+)/(.+)/([^/]+)%.java$")
  if not pkg_path or not class then
    return nil
  end
  return {
    pkg = pkg_path:gsub("/", "."),
    class = class,
  }
end

function M.parse_jrt_class_uri(uri)
  if not M.is_jrt(uri) then
    return nil
  end
  local class_path = uri:match("^jrt://.-!/modules/[^/]+/(.+)%.class$")
  local module = uri:match("^jrt://.-!/modules/([^/]+)/")
  if not class_path then
    return nil
  end
  local pkg_path, class = class_path:match("^(.*)/([^/]+)$")
  if not pkg_path or not class then
    return nil
  end
  return {
    module = module,
    class_path = class_path,
    pkg = pkg_path:gsub("/", "."),
    class = class,
  }
end

return M
