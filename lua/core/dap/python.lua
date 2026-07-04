local dap = require("dap")

dap.adapters.python = {
  type = "executable",
  command = "debugpy-adapter",
}

dap.configurations.python = {
  {
    type = "python",
    request = "launch",
    name = "Launch file",
    program = "${file}",
  },
  {
    type = "python",
    request = "launch",
    name = "Launch file (args)",
    program = "${file}",
    args = function()
      local args = vim.fn.input("Arguments: ")
      return vim.fn.split(args, " ", true)
    end,
  },
  {
    type = "python",
    request = "attach",
    name = "Attach to remote",
    connect = { host = "localhost", port = 5678 },
  },
}
