local onedark = require("onedarkpro.helpers")

local colors = onedark.get_colors("onedark")

vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = colors.red })
vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = colors.blue })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = colors.cyan })
vim.api.nvim_set_hl(0, "DapStopped", { fg = colors.yellow })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#414858" })
vim.api.nvim_set_hl(0, "DapBreakpointRejected", { bg = colors.red })

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DapBreakpointCondition", linehl = "", numhl = "" })
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint", linehl = "", numhl = "" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })
vim.fn.sign_define("DapBreakpointRejected", { text = "󰅙", texthl = "DapBreakpointRejected", linehl = "", numhl = "" })
