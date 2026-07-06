local dap = require("dap")

dap.adapters.python = {
  type = "executable",
  command = "debugpy-adapter",
}

dap.adapters.debugpy = {
  type = "executable",
  command = "debugpy-adapter",
}

dap.configurations.python = {
  {
    type = "debugpy",
    request = "launch",
    name = "Launch file",
    program = "${file}",
  },
  {
    type = "debugpy",
    request = "launch",
    name = "Launch file (args)",
    program = "${file}",
    args = function()
      local co = coroutine.running()
      vim.ui.input({ prompt = "Arguments:" }, function(args)
        vim.schedule(function()
          coroutine.resume(co, args or "")
        end)
      end)
      local args = coroutine.yield()
      return vim.fn.split(args, " ", true)
    end,
  },
  {
    type = "debugpy",
    request = "attach",
    name = "Attach to remote",
    connect = { host = "localhost", port = 5678 },
  },
}
