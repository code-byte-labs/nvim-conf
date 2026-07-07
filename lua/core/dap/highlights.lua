local onedark = require("onedarkpro.helpers")

local colors = onedark.get_colors("onedark")

vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = colors.red })
vim.api.nvim_set_hl(0, "DapBreakpointHit", { fg = colors.green })
vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = colors.blue })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = colors.cyan })
vim.api.nvim_set_hl(0, "DapStopped", { fg = colors.yellow })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#414858" })
vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = colors.red })

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
vim.fn.sign_define("DapBreakpointHit", { text = "", texthl = "DapBreakpointHit", linehl = "", numhl = "" })
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

local dap = require("dap")

local function reset_hit_breakpoints()
  for _, placed in ipairs(vim.fn.sign_getplaced("", { group = "dap_breakpoints" })) do
    for _, sign in ipairs(placed.signs or {}) do
      if sign.name == "DapBreakpointHit" then
        vim.fn.sign_place(sign.id, "dap_breakpoints", "DapBreakpoint", placed.bufnr, { lnum = sign.lnum, priority = 21 })
      end
    end
  end
end

dap.listeners.after.event_stopped["dap_breakpoint_hit_sign"] = function(session, body)
  if body.reason ~= "breakpoint" then
    return
  end

  session:request("stackTrace", { threadId = body.threadId, startFrame = 0, levels = 1 }, function(err, response)
    if err or not response or not response.stackFrames or not response.stackFrames[1] then
      return
    end

    local frame = response.stackFrames[1]
    local path = frame.source and frame.source.path
    if not path then
      return
    end

    local bufnr = vim.fn.bufnr(path)
    if bufnr < 1 then
      return
    end

    local placed = vim.fn.sign_getplaced(bufnr, { group = "dap_breakpoints", lnum = frame.line })
    for _, sign in ipairs((placed[1] or {}).signs or {}) do
      if sign.name == "DapBreakpoint" then
        vim.fn.sign_place(sign.id, "dap_breakpoints", "DapBreakpointHit", bufnr, { lnum = frame.line, priority = 21 })
      end
    end
  end)
end

dap.listeners.after.event_exited["dap_breakpoint_hit_sign"] = reset_hit_breakpoints
dap.listeners.after.event_terminated["dap_breakpoint_hit_sign"] = reset_hit_breakpoints
