local dap = require("dap")

local js_adapter = {
  type = "server",
  port = "${port}",
  executable = {
    command = "node",
    args = { "/opt/js-debug/src/dapDebugServer.js", "${port}" },
  },
}

dap.adapters["pwa-node"] = js_adapter
dap.adapters["pwa-chrome"] = js_adapter
dap.adapters["node"] = js_adapter
dap.adapters["chrome"] = js_adapter

dap.configurations.typescript = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    runtimeExecutable = "node",
    runtimeArgs = {},
    program = "${file}",
    sourceMaps = true,
    skipFiles = { "<node_internals>/**" },
  },
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch with tsx",
    runtimeExecutable = "npx",
    runtimeArgs = { "tsx" },
    program = "${file}",
    skipFiles = { "<node_internals>/**" },
  },
}

dap.configurations.javascript = {
  {
    type = "pwa-node",
    request = "launch",
    name = "Launch file",
    runtimeExecutable = "node",
    runtimeArgs = {},
    program = "${file}",
    sourceMaps = true,
    skipFiles = { "<node_internals>/**" },
  },
}

dap.configurations.typescriptreact = dap.configurations.typescript
dap.configurations.javascriptreact = dap.configurations.javascript

dap.configurations.chrome = {
  {
    type = "pwa-chrome",
    request = "launch",
    name = "Launch Chrome against localhost",
    url = "http://localhost:3000",
    webRoot = "${workspaceFolder}",
    sourceMaps = true,
    skipFiles = { "<node_internals>/**" },
  },
  {
    type = "pwa-chrome",
    request = "attach",
    name = "Attach to Chrome",
    port = 9222,
    webRoot = "${workspaceFolder}",
  },
}
