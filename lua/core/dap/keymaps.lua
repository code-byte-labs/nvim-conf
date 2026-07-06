local dap = require("dap")
local dapui = require("dapui")

vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP toggle breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  vim.ui.input({ prompt = "Breakpoint condition:" }, function(condition)
    if condition and condition ~= "" then
      dap.set_breakpoint(condition)
    end
  end)
end, { desc = "DAP conditional breakpoint" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "DAP continue/start" })
vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "DAP run to cursor" })
vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "DAP step over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "DAP step into" })
vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "DAP step out" })
vim.keymap.set("n", "<leader>dt", dapui.toggle, { desc = "DAP UI toggle" })
vim.keymap.set("n", "<leader>dr", dap.repl.toggle, { desc = "DAP REPL toggle" })
vim.keymap.set("n", "<leader>dq", dap.terminate, { desc = "DAP terminate" })
