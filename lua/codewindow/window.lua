local M = {}

local config = require("codewindow.config").get()
local utils = require("codewindow.utils")
local minimap_hl = require("codewindow.highlight")

function M.create_window()
  local window = {}

  window.buffer = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(window.buffer, "CodeWindow")
  vim.api.nvim_buf_set_option(window.buffer, "filetype", "Codewindow")

  window.window = nil
  window.augroup = vim.api.nvim_create_augroup("CodewindowAugroup", {})
  window.focused = false

  function window:open()
    local current_window = vim.api.nvim_get_current_win()

    local minimap_height = vim.fn.winheight(current_window)
    if config.max_minimap_height then
      minimap_height = math.min(minimap_height, config.max_minimap_height)
    end

    if minimap_height < 2 then
      return
    end

    local window_config = {
      relative = "win",
      win = current_window,
      anchor = "NE",
      width = config.minimap_width + 4,
      height = minimap_height - 2,
      row = 0,
      col = vim.api.nvim_win_get_width(current_window),
      focusable = false,
      zindex = config.z_index,
      style = "minimal",
      border = config.window_border,
    }

    self.window = vim.api.nvim_open_win(self.buffer, false, window_config)
    vim.api.nvim_win_set_option(
      self.window,
      "winhl",
      "Normal:CodewindowBackground,FloatBorder:CodewindowBorder"
    )
    self.parent_win = current_window

    vim.defer_fn(function()
      minimap_hl.display_screen_bounds(self)
    end, 0)
    self:setup_autocmds()
  end

  function window:close()
    if not self:is_open() then
      return
    end
    self:clear_autocmds()
    vim.api.nvim_win_hide(self.window)
    self.window = nil
    self.parent_win = nil
    self.focused = false
  end

  function window:is_open()
    return self.window ~= nil
  end

  function window:setup_autocmds()
    self:clear_autocmds()
    vim.api.nvim_create_autocmd({ "WinScrolled" }, {
      callback = function()
        if vim.api.nvim_get_current_win() ~= self.parent_win then
          return
        end

        self:center()
        minimap_hl.display_screen_bounds(self)
      end,
      group = self.augroup,
    })
    vim.api.nvim_create_autocmd({ "WinEnter", "BufEnter" }, {
      callback = function(args)
        if args.buf == self.buffer then
          return
        end

        self:close()
        self:open()
      end,
      group = self.augroup,
    })
    vim.api.nvim_create_autocmd({ "WinClosed" }, {
      buffer = window.buffer,
      callback = function()
        self:close()
      end,
    })
    vim.api.nvim_create_autocmd({ "CursorMoved" }, {
      buffer = window.buffer,
      callback = function()
        local topline = utils.get_top_line(window.parent_win)
        local botline = utils.get_bot_line(window.parent_win)
        local center = math.floor((topline + botline) / 2 / 4)
        local row = vim.api.nvim_win_get_cursor(window.window)[1] - 1
        local diff = row - center
        self:scroll_parent(diff * 4)
      end,
      group = self.augroup,
    })
  end

  function window:scroll_parent(amount)
    utils.scroll_window(window.parent_win, amount)
    self:center()

    minimap_hl.display_screen_bounds(window)
  end

  function window:clear_autocmds()
    vim.api.nvim_clear_autocmds({ group = self.augroup })
  end

  function window:center()
    local topline = utils.get_top_line(self.parent_win)
    local botline = utils.get_bot_line(self.parent_win)

    local difference = math.ceil((botline - topline) / 4)

    local top_y = math.floor(topline / 4)
    local bot_y = top_y + difference - 1

    local minimap_top = utils.get_top_line(self.window)
    local minimap_bot = utils.get_bot_line(self.window)

    local top_diff = top_y - minimap_top
    local bot_diff = minimap_bot - bot_y

    local diff = top_diff - bot_diff
    if math.abs(diff) <= 1 then
      return
    end
    if diff < 0 then
      diff = math.ceil(diff / 2)
    else
      diff = math.floor(diff / 2)
    end

    utils.scroll_window(self.window, diff)
  end

  function window:focus(value)
    if not self:is_open() then
      return
    end
    if self.focused == value then
      return
    end

    self.focused = value
    if self.focused then
      vim.api.nvim_set_current_win(self.window)
    else
      vim.api.nvim_set_current_win(self.parent_win)
    end
  end

  function window:is_focused()
    return self.focused
  end

  return window
end

return M
