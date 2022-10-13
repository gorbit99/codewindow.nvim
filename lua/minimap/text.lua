local utils = require('minimap.utils')
local config = require('minimap.config').get_config()
local inspect = require('inspect')

local minimap_err = require('minimap.errors')
local minimap_hl = require('minimap.highlight')

local M = {}

local function is_whitespace(chr)
  return chr == " " or chr == "\t" or chr == ""
end

local function coord_to_flag(x, y)
  x = x - 1
  y = y - 1
  return math.pow(2, y % 4) * ((x % 2 == 0) and 1 or 16)
end

function M.compress_text(lines)
  local scanned_text = {}
  for _ = 0, math.floor(#lines / 4) do
    local line = {}
    for _ = 1, config.minimap_width do
      table.insert(line, 0)
    end
    table.insert(scanned_text, line)
  end

  for y = 1, #lines do
    local current_line = lines[y]
    for x = 1, config.minimap_width * 2 do

      local any_printable = false
      for dx = 1, config.width_multiplier do
        local actual_x = (x - 1) * config.width_multiplier + (dx - 1) + 1
        local chr = current_line:sub(actual_x, actual_x)
        if not is_whitespace(chr) then
          any_printable = true
        end
      end

      if any_printable then
        local flag = coord_to_flag(x, y)
        local chr_x = math.floor((x - 1) / 2) + 1
        local chr_y = math.floor((y - 1) / 4) + 1
        scanned_text[chr_y][chr_x] = scanned_text[chr_y][chr_x] + flag
      end
    end
  end

  local minimap_text = {}
  for y = 1, #scanned_text do
    local line = ""
    for _, flag in ipairs(scanned_text[y]) do
      line = line .. utils.flag_to_char(flag)
    end
    table.insert(minimap_text, line)
  end

  return minimap_text
end

function M.update_minimap(current_buffer, window)
  vim.api.nvim_buf_set_option(window.buffer, 'modifiable', true)
  local lines = vim.api.nvim_buf_get_lines(current_buffer, 0, -1, true)

  local error_text = minimap_err.get_lsp_errors(current_buffer)
  local minimap_text = M.compress_text(lines)

  local text = {}
  for i = 1, #minimap_text do
    local line = error_text[i] .. minimap_text[i]
    table.insert(text, line)
  end

  vim.api.nvim_buf_set_lines(window.buffer, 0, -1, true, text)

  local highlights = minimap_hl.extract_highlighting(current_buffer, lines)
  if highlights then
    minimap_hl.apply_highlight(highlights, window.buffer)
  end

  minimap_hl.display_screen_bounds(window)
  vim.api.nvim_buf_set_option(window.buffer, 'modifiable', false)
end

return M
