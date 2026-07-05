return {
  position_encoding = "utf-8",
  -- basedpyright 负责 hover/类型信息，ruff 只做 lint 诊断与 code action，
  -- 关闭 ruff 的 hover 以避免与 basedpyright 重复。
  on_attach = function(client)
    client.server_capabilities.hoverProvider = false
  end,
}
