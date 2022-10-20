local M = {}

local utils = require('codewindow.utils')

local minimap_txt = require('codewindow.text')
local window = nil

local minimap_hl = require('codewindow.highlight')

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

local function scroll_parent_window(amount)
  utils.scroll_window(window.parent_win, amount)
  center_minimap()

  minimap_hl.display_screen_bounds(window)
end

local augroup

function M.close_minimap()
  vim.api.nvim_buf_delete(window.buffer, { force = true });
  vim.api.nvim_clear_autocmds({ group = augroup })
  window = nil
end

local function setup_minimap_autocmds(parent_buf, on_switch_window)
  augroup = vim.api.nvim_create_augroup('CodewindowAugroup', {})
  vim.api.nvim_create_autocmd({ 'WinScrolled' }, {
    buffer = parent_buf,
    callback = function()
      center_minimap()
      minimap_hl.display_screen_bounds(window)
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave', 'DiagnosticChanged' }, {
    buffer = parent_buf,
    callback = function()
      vim.defer_fn(function()
        minimap_txt.update_minimap(vim.api.nvim_win_get_buf(window.parent_win), window)
      end, 0)
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'CursorMoved' }, {
    buffer = window.buffer,
    callback = function()
      local topline = utils.get_top_line(window.parent_win)
      local botline = utils.get_bot_line(window.parent_win)
      local center = math.floor((topline + botline) / 2 / 4)
      local row = vim.api.nvim_win_get_cursor(window.window)[1] - 1
      local diff = row - center
      scroll_parent_window(diff * 4)
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'BufWinLeave' }, {
    buffer = window.buffer,
    callback = function()
      vim.defer_fn(function()
        local new_buffer = vim.api.nvim_get_current_buf()
        vim.api.nvim_win_set_buf(window.window, window.buffer)
        vim.api.nvim_win_set_buf(window.parent_win, new_buffer)
        M.toggle_focused()
      end, 0)
    end,
    group = augroup,
  })
  vim.api.nvim_create_autocmd({ 'WinClosed' }, {
    buffer = window.buffer,
    callback = function()
      if window == nil then
        return
      end
      M.close_minimap()
    end
  })
  vim.api.nvim_create_autocmd({ 'WinEnter', 'BufEnter' }, {
    callback = function(args)
      if args.buf == window.buffer then
        return
      end
      on_switch_window()
    end,
    group = augroup
  })
end

local function get_window_height(current_window)
  local window_height = vim.fn.winheight(current_window)
  return window_height
end

local function get_window_config(current_window)
  local config = require('codewindow.config').get()
  local minimap_height = get_window_height(current_window)
  if config.max_minimap_height then
    minimap_height = math.min(minimap_height, config.max_minimap_height)
  end
  return {
    relative = "win",
    win = current_window,
    anchor = "NE",
    width = config.minimap_width + 3,
    height = minimap_height - 2,
    row = 0,
    col = vim.api.nvim_win_get_width(current_window),
    focusable = false,
    zindex = config.z_index,
    style = 'minimal',
    border = 'single',
  }
end

function M.create_window(buffer, on_switch_window)
  local config = require('codewindow.config').get()
  local filetype = vim.bo.filetype
  for _, v in ipairs(config.exclude_filetypes) do
    if v == filetype then
      if window == nil then
        return nil
      else
        if vim.api.nvim_win_is_valid(window.parent_win) then
          vim.api.nvim_win_set_config(window.window, get_window_config(window.parent_win))
          return nil
        else
          M.close_minimap()
        end
      end
    end
  end

  if window and vim.api.nvim_get_current_buf() == window.buffer then
    return nil
  end

  local current_window = vim.api.nvim_get_current_win()

  local window_height = get_window_height(current_window)
  if window_height <= 2 then
    return nil
  end

  if window then
    vim.api.nvim_win_set_config(window.window, get_window_config(current_window))

    window.parent_win = current_window
    window.focused = false
  else
    local minimap_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(minimap_buf, 'CodeWindow')
    vim.api.nvim_buf_set_option(minimap_buf, 'filetype', 'Codewindow')

    local minimap_win = vim.api.nvim_open_win(minimap_buf, false, get_window_config(current_window))

    vim.api.nvim_win_set_option(minimap_win, 'winhl',
      'Normal:Normal,VertSplit:CodewindowBorder')

    window = {
      buffer = minimap_buf,
      window = minimap_win,
      parent_win = vim.api.nvim_get_current_win(),
      focused = false,
    }
  end

  vim.api.nvim_clear_autocmds({ group = augroup })
  setup_minimap_autocmds(buffer, on_switch_window)

  return window
end

function M.set_focused(value)
  if window == nil or window.focused == value then
    return
  end
  window.focused = value
  if window.focused then
    vim.api.nvim_set_current_win(window.window)
  else
    vim.api.nvim_set_current_win(window.parent_win)
  end
end

function M.toggle_focused()
  if window == nil then
    return
  end
  M.set_focused(not window.focused)
end

function M.scroll_minimap(amount)
  scroll_parent_window(4 * amount)
  utils.scroll_window(window.window, amount)
end

function M.scroll_minimap_by_page(amount)
  local window_height = vim.api.nvim_win_get_height(window.parent_win)
  local actual_amount = math.floor(window_height * amount);
  actual_amount = actual_amount + (4 - actual_amount % 4) % 4
  scroll_parent_window(actual_amount)
  utils.scroll_window(window.window, actual_amount / 4)
end

function M.scroll_minimap_top()
  scroll_parent_window(-math.huge)
  utils.scroll_window(window.window, -math.huge)
end

function M.scroll_minimap_bot()
  scroll_parent_window(math.huge)
  utils.scroll_window(window.window, math.huge)
end

function M.is_minimap_open()
  return window ~= nil
end

function M.get_minimap_window()
  return window
end

return M
