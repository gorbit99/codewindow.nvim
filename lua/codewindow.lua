local M = {}

local minimap_txt = require('codewindow.text')
local minimap_win = require('codewindow.window')
local minimap_hl  = require('codewindow.highlight')

local defer = vim.schedule
local api = vim.api

function M.open_minimap()
  local current_buffer = api.nvim_get_current_buf()
  local window
  window = minimap_win.create_window(current_buffer, function()
    defer(M.open_minimap)
  end, function()
    defer(function()
      minimap_hl.display_cursor(window)
    end)
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
  config = require('codewindow.config').setup(config)

  minimap_hl.setup()

  api.nvim_create_autocmd({'BufWinEnter'}, {
    callback = function()
      local filetype = vim.bo.filetype
      local should_open = false
      if type(config.auto_enable) == 'boolean' then
        should_open = config.auto_enable
      else
        for _, v in ipairs(config.auto_enable) do
          if v == filetype then
            should_open = true
          end
        end
      end

      if config.max_lines then
        if api.nvim_buf_line_count(api.nvim_get_current_buf()) > config.max_lines then
          should_open = false
        end
      end

      if vim.bo.buftype == 'terminal' and not config.active_in_terminals then
        return
      end

      if should_open then
        defer(M.open_minimap)
      end
    end
  })

  api.nvim_create_autocmd({'TabLeave'}, {
    callback = function()
        defer(M.close_minimap)
    end
  })
end

return M
