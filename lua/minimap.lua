local M = {}

local minimap_hl  = require('minimap.highlight')
local minimap_txt = require('minimap.text')
local minimap_win = require('minimap.window')

local buffer_change_autocmd = nil

local function create_minimap()
  local current_buffer = vim.api.nvim_get_current_buf()

  local window = minimap_win.create_window(current_buffer, function(window)
    minimap_hl.display_screen_bounds(window)
  end)

  if window == nil then
    return
  end

  minimap_txt.update_minimap(current_buffer, window)

  vim.keymap.set('n', '<C-w>m', function()
    minimap_win.toggle_minimap_focus()
  end, { silent = true, noremap = true })

  if buffer_change_autocmd == nil then
    buffer_change_autocmd = vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
      callback = function()
        create_minimap()
      end
    })
  end
end

function M.setup()
  vim.api.nvim_create_user_command('DrawMinimap', create_minimap, {})
end

return M
