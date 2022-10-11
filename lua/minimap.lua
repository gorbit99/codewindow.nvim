local minimap_hl  = require('minimap.highlight')
local minimap_txt = require('minimap.text')
local minimap_win = require('minimap.window')
local minimap_err = require('minimap.errors')

local M = {}

local function draw_minimap()
  local current_buffer = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, -1, true)

  local error_text = minimap_err.get_lsp_errors(current_buffer, lines)
  local minimap_text = minimap_txt.compress_text(lines)

  local text = {}
  for i = 1, #minimap_text do
    local line = error_text[i] .. minimap_text[i]
    table.insert(text, line)
  end

  local window = minimap_win.create_window(current_buffer, function(window)
    minimap_hl.display_screen_bounds(window)
  end)

  vim.api.nvim_buf_set_lines(window.buffer, 0, -1, true, text)

  local highlights = minimap_hl.extract_highlighting(current_buffer, lines)
  minimap_hl.apply_highlight(highlights, window.buffer)
  minimap_hl.display_screen_bounds(window)

  vim.keymap.set('n', '<C-w>m', function()
    minimap_win.toggle_minimap_focus()
  end, { silent = true, noremap = true })
end

function M.setup()
  vim.api.nvim_create_user_command('DrawMinimap', draw_minimap, {})
end

-- vim.api.nvim_create_autocmd({ 'WinLeave' })

return M
