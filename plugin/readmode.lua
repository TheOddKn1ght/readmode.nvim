if vim.g.loaded_readmode then return end
vim.g.loaded_readmode = true

vim.api.nvim_create_user_command("Readmode", function(opts)
  local mode = opts.args
  if mode == "enable" then
    require("readmode").enable()
  elseif mode == "disable" then
    require("readmode").disable()
  elseif mode == "" or mode == "toggle" then
    require("readmode").toggle()
  else
    vim.notify("Usage: Readmode [enable|disable|toggle]", vim.log.levels.ERROR)
  end
end, {
  nargs = "?", desc = "Toggle centered reading mode",
  complete = function() return { "enable", "disable", "toggle" } end,
})
