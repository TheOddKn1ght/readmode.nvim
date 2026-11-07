local M = {}

local defaults = { width = 80, padding = 2 }
local config = vim.deepcopy(defaults)
local session

local function geometry()
  local columns = vim.o.columns
  local height = math.max(1, vim.o.lines - vim.o.cmdheight)
  local padding = math.min(config.padding, math.floor((math.min(columns, height) - 1) / 2))
  local width = math.max(1, math.min(config.width, columns - padding * 2))
  return { width = width, height = math.max(1, height - padding * 2),
    row = padding, col = math.floor((columns - width) / 2) },
    { width = columns, height = height, row = 0, col = 0 }
end

local function float_config(size, zindex)
  return vim.tbl_extend("force", size, {
    relative = "editor", style = "minimal", border = "none", zindex = zindex,
  })
end

local function resize()
  if not session then return end
  local reading, backdrop = geometry()
  if vim.api.nvim_win_is_valid(session.backdrop) then
    vim.api.nvim_win_set_config(session.backdrop, float_config(backdrop, 40))
  end
  if vim.api.nvim_win_is_valid(session.window) then
    vim.api.nvim_win_set_config(session.window, float_config(reading, 50))
  end
end

---Leave reading mode and restore the original window and reading position.
function M.disable()
  if not session then return end
  local old = session
  session = nil
  vim.api.nvim_del_augroup_by_id(old.group)
  local view
  if vim.api.nvim_win_is_valid(old.window) then
    view = vim.api.nvim_win_call(old.window, vim.fn.winsaveview)
    vim.api.nvim_win_close(old.window, true)
  end
  if vim.api.nvim_win_is_valid(old.backdrop) then
    vim.api.nvim_win_close(old.backdrop, true)
  end
  if vim.api.nvim_buf_is_valid(old.backdrop_buffer) then
    vim.api.nvim_buf_delete(old.backdrop_buffer, { force = true })
  end
  if vim.api.nvim_win_is_valid(old.origin) then
    vim.api.nvim_set_current_win(old.origin)
    if view and vim.api.nvim_win_get_buf(old.origin) == old.buffer then
      vim.fn.winrestview(view)
    end
  end
end

---Open the current buffer in a centered reading window.
function M.enable()
  if session then return end
  local origin = vim.api.nvim_get_current_win()
  local buffer = vim.api.nvim_get_current_buf()
  if vim.bo[buffer].buftype ~= "" then
    vim.notify("readmode: open a regular text buffer first", vim.log.levels.WARN)
    return
  end
  local view = vim.fn.winsaveview()
  local reading, backdrop = geometry()
  local backdrop_buffer = vim.api.nvim_create_buf(false, true)
  vim.bo[backdrop_buffer].bufhidden = "wipe"
  local backdrop_options = float_config(backdrop, 40)
  backdrop_options.focusable = false
  local background = vim.api.nvim_open_win(backdrop_buffer, false, backdrop_options)
  vim.wo[background].winhighlight = "Normal:Normal,NormalNC:Normal,EndOfBuffer:Normal"
  vim.wo[background].winblend = 0
  local window = vim.api.nvim_open_win(buffer, true, float_config(reading, 50))
  for option, value in pairs({
    wrap = true, linebreak = true, breakindent = true, number = false,
    relativenumber = false, cursorline = false, cursorcolumn = false,
    foldcolumn = "0", foldenable = false, signcolumn = "no", colorcolumn = "", list = false,
    winblend = 0, scrolloff = 5,
    winhighlight = "Normal:Normal,NormalNC:Normal,EndOfBuffer:Normal",
  }) do
    vim.wo[window][option] = value
  end
  vim.fn.winrestview(view)
  local group = vim.api.nvim_create_augroup("ReadmodeSession", { clear = true })
  session = { origin = origin, buffer = buffer, window = window,
    backdrop = background, backdrop_buffer = backdrop_buffer, group = group }
  vim.api.nvim_create_autocmd("VimResized", { group = group, callback = resize })
  vim.api.nvim_create_autocmd("WinClosed", {
    group = group, pattern = tostring(window), callback = function()
      -- Finish cleanup after Neovim completes closing the window.
      vim.schedule(function()
        if session and session.window == window then M.disable() end
      end)
    end,
  })
  vim.api.nvim_create_autocmd("TabLeave", { group = group, callback = M.disable })
end

function M.toggle()
  if session then M.disable() else M.enable() end
end

function M.is_enabled()
  return session ~= nil
end

---Configure the text width and minimum space around the reading window.
function M.setup(opts)
  opts = opts or {}
  vim.validate({ opts = { opts, "table" } })
  local next_config = vim.tbl_extend("force", defaults, opts)
  for _, key in ipairs({ "width", "padding" }) do
    local value = next_config[key]
    if type(value) ~= "number" or value ~= math.floor(value)
        or value < (key == "width" and 1 or 0) or value == math.huge then
      error("readmode: " .. key .. " must be a " .. (key == "width" and "positive" or "non-negative") .. " integer")
    end
  end
  config = next_config
  resize()
end

return M
