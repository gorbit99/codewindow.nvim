local M = {}

local utils = require('minimap.utils')

local config = require('minimap.config').get_config()
local minimap_txt = require('minimap.text')
local window = nil
local guicursor_prev = nil

local function center_minimap()
  local topline = utils.get_top_line(window.parent_win)
  local botline = utils.get_bot_line(window.parent_win)

  local difference = math.ceil((botline - topline) / 4)

  local top_y = math.floor(topline / 4)
  local bot_y = top_y + difference - 1

  local minimap_top = utils.get_top_line(window.window)
  local minimap_bot = utils.get_bot_line(window.window)

  local top_diff = top_y - minimap_top;
  local bot_diff = minimap_bot - bot_y;

  local diff = top_diff - bot_diff;
  if math.abs(diff) <= 1 then
    return
  end
  if diff < 0 then
    diff = math.ceil(diff / 2)
  else
    diff = math.floor(diff / 2)
  end

  utils.scroll_window(window.window, diff)
end

local function scroll_parent_window(amount, on_window_scroll)
  utils.scroll_window(window.parent_win, amount)
  center_minimap()

  on_window_scroll(window)
end

local function setup_minimap_autocmds(on_window_scroll, parent_buf)
  local augroup = vim.api.nvim_create_augroup('CodewindowAugroup', {})
  vim.api.nvim_create_autocmd({ 'WinScrolled' }, {
    buffer = parent_buf,
    callback = function()
      center_minimap()
      on_window_scroll(window)
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave', 'DiagnosticChanged' }, {
    buffer = parent_buf,
    callback = function()
      minimap_txt.update_minimap(vim.api.nvim_win_get_buf(window.parent_win), window)
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'WinEnter' }, {
    buffer = window.buffer,
    callback = function()
      guicursor_prev = vim.go.guicursor
      vim.go.guicursor = 'a:CodewindowCursor'
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'WinLeave' }, {
    buffer = window.buffer,
    callback = function()
      vim.go.guicursor = guicursor_prev
    end,
    group = augroup,
  })
end

local function setup_minimap_keymap(on_window_scroll)
  vim.keymap.set('n', 'j', function()
    scroll_parent_window(4, on_window_scroll)
  end, { buffer = window.buffer })
  vim.keymap.set('n', 'k', function()
    scroll_parent_window(-4, on_window_scroll)
  end, { buffer = window.buffer })
  vim.keymap.set('n', '<C-d>', function()
    local window_height = vim.api.nvim_win_get_height(window.parent_win)
    scroll_parent_window(math.floor(window_height / 2), on_window_scroll)
  end, { buffer = window.buffer })
  vim.keymap.set('n', '<C-u>', function()
    local window_height = vim.api.nvim_win_get_height(window.parent_win)
    scroll_parent_window(-math.floor(window_height / 2), on_window_scroll)
  end, { buffer = window.buffer })
  vim.keymap.set('n', 'G', function()
    scroll_parent_window(math.huge, on_window_scroll)
  end, { buffer = window.buffer })
  vim.keymap.set('n', 'gg', function()
    scroll_parent_window(-math.huge, on_window_scroll)
  end, { buffer = window.buffer })
end

function M.create_window(buffer, on_window_scroll)
  if window and vim.api.nvim_get_current_buf() == window.buffer then
    return nil
  end

  local current_window = vim.api.nvim_get_current_win()
  local window_height = vim.api.nvim_win_get_height(current_window)
  local minimap_buf = vim.api.nvim_create_buf(false, true)

  if window_height <= 2 then
    return nil
  end

  if window then
    if vim.api.nvim_win_is_valid(window.window) then
      vim.api.nvim_win_close(window.window, { force = true })
    end
    if vim.api.nvim_buf_is_valid(window.buffer) then
      vim.api.nvim_buf_delete(window.buffer, { force = true })
    end
    window = nil
  end

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

  window = {
    buffer = minimap_buf,
    window = minimap_win,
    parent_win = vim.api.nvim_get_current_win(),
  }

  setup_minimap_autocmds(on_window_scroll, buffer)

  setup_minimap_keymap(on_window_scroll)

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
