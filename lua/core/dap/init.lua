local dap = require("dap")
local dapui = require("dapui")
local onedark = require("onedarkpro.helpers")
local dapvisualtext = require("nvim-dap-virtual-text")

local colors = onedark.get_colors("onedark")
vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = colors.red })
vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = colors.blue })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = colors.cyan })
vim.api.nvim_set_hl(0, "DapStopped", { fg = colors.yellow })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#414858" })
vim.api.nvim_set_hl(0, "DapBreakpointRejected", { bg = colors.red })
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
vim.fn.sign_define(
  "DapBreakpointCondition",
  { text = "", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
)
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
vim.fn.sign_define(
  "DapBreakpointRejected",
  { text = "󰅙", texthl = "DapBreakpointRejected", linehl = "", numhl = "" }
)

dapui.setup()

dap.listeners.before.attach.dapui = dapui.open
dap.listeners.before.launch.dapui = dapui.open
dap.listeners.before.event_terminated.dapui = dapui.close
dap.listeners.before.event_exited.dapui = dapui.close

vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "DAP conditional breakpoint" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue/start" })
vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "DAP run to cursor" })
vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
vim.keymap.set("n", "<leader>dt", dapui.toggle, { desc = "DAP UI toggle" })
vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "DAP REPL toggle" })
vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "DAP terminate" })

require("core.dap.go")
require("core.dap.python")
require("core.dap.js")
dapvisualtext.setup({})
