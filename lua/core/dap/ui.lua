local dap = require("dap")
local dapui = require("dapui")

dapui.setup({
  icons = {
    collapsed = "",
    current_frame = "",
    expanded = "",
  },
  layouts = {
    {
      elements = {
        { id = "watches", size = 0.4 },
        { id = "repl", size = 0.6 },
      },
      size = 40,
      position = "left",
    },
    {
      elements = {
        "scopes",
      },
      size = math.floor(vim.o.lines * 0.4),
      position = "bottom",
    },
  },
  mappings = {
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "e",
    repl = "r",
    toggle = "t",
    watch = "w",
  },
  element_mappings = {},
  expand_lines = vim.fn.has("nvim-0.7") == 1,
  force_buffers = true,
  floating = {
    max_height = nil,
    max_width = nil,
    border = "single",
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  controls = {
    enabled = vim.fn.exists("+winbar") == 1,
    element = "repl",
    icons = {
      pause = "",
      play = "",
      step_into = "",
      step_over = "",
      step_out = "",
      step_back = "",
      run_last = "",
      terminate = "",
      disconnect = "",
    },
  },
  render = {
    max_type_length = nil,
    max_value_lines = 100,
    indent = 1,
  },
  wrap = false,
})

dap.listeners.before.attach.dapui = dapui.open
dap.listeners.before.launch.dapui = dapui.open
dap.listeners.before.event_terminated.dapui = dapui.close
dap.listeners.before.event_exited.dapui = dapui.close
