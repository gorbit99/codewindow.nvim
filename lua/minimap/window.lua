local M = {}

local config = require('minimap.config').get_config()

local window = nil
local guicursor_prev = nil

function M.create_window(buffer, on_window_scroll)
  if window then
    vim.api.nvim_win_close(window.window, { force = true })
    vim.api.nvim_buf_delete(window.buffer, { force = true })
    window = nil
  end
  local current_window = vim.api.nvim_get_current_win()
  local window_height = vim.api.nvim_win_get_height(current_window)
  local minimap_buf = vim.api.nvim_create_buf(false, true)
  local minimap_win = vim.api.nvim_open_win(minimap_buf, false, {
    relative = "win",
    win = current_window,
    anchor = "NE",
    width = config.minimap_width + 3,
    height = window_height - 2,
    row = 0,
    col = vim.api.nvim_win_get_width(current_window),
    focusable = false,
    zindex = 1,
    style = 'minimal',
    border = 'single',
  })

  vim.api.nvim_win_set_option(minimap_win, 'winhl', 'Normal:Normal,FloatBorder:Normal')

  local augroup = vim.api.nvim_create_augroup("CodewindowAugroup", {})
  vim.api.nvim_create_autocmd({ 'WinScrolled' }, {
    buffer = buffer,
    callback = function()
      on_window_scroll(window)
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'WinEnter' }, {
    buffer = minimap_buf,
    callback = function()
      guicursor_prev = vim.go.guicursor
      vim.go.guicursor = 'a:CodewindowCursor'
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'WinLeave' }, {
    buffer = minimap_buf,
    callback = function()
      vim.go.guicursor = guicursor_prev
    end,
    group = augroup,
  })

  vim.keymap.set('n', 'j', function()
    print("Down")
  end, { buffer = minimap_buf })
  vim.keymap.set('n', 'k', function()
    print("Up")
  end, { buffer = minimap_buf })

  window = {
    buffer = minimap_buf,
    window = minimap_win,
    parent_win = vim.api.nvim_get_current_win(),
  }

  return window
end

function M.toggle_minimap_focus()
  if vim.api.nvim_get_current_win() == window.window then
    vim.api.nvim_set_current_win(window.parent_win)
  else
    vim.api.nvim_set_current_win(window.window)
  end
end

return M
