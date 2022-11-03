local M = {}

local minimap_txt = require("codewindow.text")
local minimap_win = require("codewindow.window")
local minimap_hl = require("codewindow.highlight")

local window

function M.open_minimap()
  -- window = minimap_win.create_window(current_buffer, function()
  --   vim.defer_fn(M.open_minimap, 0)
  -- end, function()
  --   vim.defer_fn(function()
  --     minimap_hl.display_cursor(window)
  --   end, 0)
  -- end)

  -- if window == nil then
  --   return
  -- end

  window:open()

  local current_buffer = vim.api.nvim_get_current_buf()
  minimap_txt.update_minimap(current_buffer, window)
end

function M.close_minimap()
  if window:is_open() then
    window:close()
  end
end

function M.toggle_focus()
  window:focus(not window:is_focused())
end

function M.toggle_minimap()
  if window:is_open() then
    M.close_minimap()
  else
    M.open_minimap()
  end
end

function M.apply_default_keybinds()
  vim.keymap.set("n", "<leader>mo", M.open_minimap, { desc = "Open minimap" })
  vim.keymap.set(
    "n",
    "<leader>mf",
    M.toggle_focus,
    { desc = "Toggle minimap focus" }
  )
  vim.keymap.set("n", "<leader>mc", M.close_minimap, { desc = "Close minimap" })
  vim.keymap.set(
    "n",
    "<leader>mm",
    M.toggle_minimap,
    { desc = "Toggle minimap" }
  )
end

function M.setup(config)
  -- config = require('codewindow.config').setup(config)

  window = minimap_win.create_window()

  minimap_hl.setup()

  -- vim.api.nvim_create_autocmd({ 'BufEnter', 'WinEnter' }, {
  --   callback = function()
  --     local filetype = vim.bo.filetype
  --     local should_open = false
  --     if type(config.auto_enable) == 'boolean' then
  --       should_open = config.auto_enable
  --     else
  --       for _, v in ipairs(config.auto_enable) do
  --         if v == filetype then
  --           should_open = true
  --         end
  --       end
  --     end
  --
  --     if config.max_lines then
  --       if vim.api.nvim_buf_line_count(vim.api.nvim_get_current_buf()) > config.max_lines then
  --         should_open = false
  --       end
  --     end
  --
  --     if should_open then
  --       vim.defer_fn(M.open_minimap, 0)
  --     end
  --   end
  -- })
end

return M
