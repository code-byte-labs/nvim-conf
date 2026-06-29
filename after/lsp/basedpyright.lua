return {
  -- ruff 负责 lint，basedpyright 专注类型检查：关闭与 ruff 重叠的「未使用」类诊断
  -- (reportUnusedImport=F401, reportUnusedVariable=F841 等)，避免同一问题两边重复报。
  -- 不提供 on_attach，保留 lspconfig 默认的 LspPyrightOrganizeImports / LspPyrightSetPythonPath 命令。
  settings = {
    basedpyright = {
      analysis = {
        diagnosticSeverityOverrides = {
          reportUnusedImport = "none",
          reportUnusedClass = "none",
          reportUnusedFunction = "none",
          reportUnusedVariable = "none",
          reportUnusedExpression = "none",
        },
      },
    },
  },
}
