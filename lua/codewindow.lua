local M = {}

local minimap_txt = require('codewindow.text')
local minimap_win = require('codewindow.window')

function M.open_minimap()
  local current_buffer = vim.api.nvim_get_current_buf()
  local window
  window = minimap_win.create_window(current_buffer, function()
    vim.defer_fn(M.open_minimap, 0)
  end)

  if window == nil then
    return
  end

  minimap_txt.update_minimap(current_buffer, window)
end

function M.close_minimap()
  if minimap_win.is_minimap_open() then
    minimap_win.close_minimap()
  end
end

function M.toggle_focus()
  if minimap_win.is_minimap_open() then
    minimap_win.toggle_focused()
  end
end

function M.toggle_minimap()
  if minimap_win.is_minimap_open() then
    M.close_minimap()
  else
    M.open_minimap()
  end
end

function M.apply_default_keybinds()
  vim.keymap.set('n', '<leader>mo', M.open_minimap, { desc = 'Open minimap' })
  vim.keymap.set('n', '<leader>mf', M.toggle_focus, { desc = 'Toggle minimap focus' })
  vim.keymap.set('n', '<leader>mc', M.close_minimap, { desc = 'Close minimap' })
  vim.keymap.set('n', '<leader>mm', M.toggle_minimap, { desc = 'Toggle minimap' })
end

function M.setup(config)
  if config ~= nil then
    require('codewindow.config').setup(config)
  end
end

return M
