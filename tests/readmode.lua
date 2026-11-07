vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.cmd("runtime plugin/readmode.lua")
local readmode = require("readmode")
local function check(value, message)
  assert(value, message)
end

local ok, err = pcall(function()
  vim.o.columns = 120
  vim.o.lines = 40
  vim.cmd("vsplit")
  local origin = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_get_current_buf()
  vim.wo.number = true
  vim.wo.wrap = false
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "first", "second", "third" })
  local initial_windows = #vim.api.nvim_list_wins()
  vim.cmd("Readmode enable")
  local window = vim.api.nvim_get_current_win()
  check(readmode.is_enabled(), "enable session")
  check(vim.api.nvim_win_get_buf(window) == buffer, "share original buffer")
  check(vim.api.nvim_win_get_width(window) == 80, "default width")
  check(vim.api.nvim_win_get_config(window).col == 20, "center horizontally")
  check(vim.wo.wrap and vim.wo.linebreak and not vim.wo.number, "reading options")
  vim.api.nvim_win_set_cursor(window, { 3, 0 })
  vim.api.nvim_buf_set_lines(buffer, 0, 1, false, { "edited" })
  readmode.enable()
  check(#vim.api.nvim_list_wins() == initial_windows + 2, "enable is idempotent")
  readmode.setup({ width = 60 })
  check(vim.api.nvim_win_get_width(window) == 60, "live configuration")
  vim.o.columns = 45
  vim.api.nvim_exec_autocmds("VimResized", {})
  check(vim.api.nvim_win_get_width(window) == 41, "fit narrow terminal")
  readmode.setup({ width = 80, padding = 100 })
  vim.o.columns = 12
  vim.o.lines = 5
  vim.api.nvim_exec_autocmds("VimResized", {})
  check(vim.api.nvim_win_get_width(window) >= 1 and vim.api.nvim_win_get_height(window) >= 1,
    "fit tiny terminal with oversized padding")
  vim.o.columns = 120
  vim.o.lines = 40
  readmode.setup()
  vim.cmd("Readmode disable")
  check(not readmode.is_enabled(), "disable session")
  check(vim.api.nvim_get_current_win() == origin, "restore original window")
  check(#vim.api.nvim_list_wins() == initial_windows, "remove both floats")
  check(vim.wo.number and not vim.wo.wrap, "preserve original options")
  check(vim.api.nvim_win_get_cursor(origin)[1] == 3, "preserve reading position")
  check(vim.api.nvim_buf_get_lines(buffer, 0, 1, false)[1] == "edited", "preserve edits")
  readmode.disable()
  readmode.toggle()
  vim.cmd("close")
  vim.wait(100, function() return not readmode.is_enabled() end)
  check(not readmode.is_enabled() and #vim.api.nvim_list_wins() == initial_windows, "manual close cleanup")
  readmode.enable()
  vim.cmd("tabnew")
  check(not readmode.is_enabled(), "tab switch cleanup")
  vim.cmd("tabclose")
  vim.bo.buftype = "nofile"
  readmode.enable()
  check(not readmode.is_enabled(), "skip special buffers")
  check(not pcall(readmode.setup, { width = 0 }), "reject invalid configuration")
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
print("readmode: all checks passed")
vim.cmd("qa!")
