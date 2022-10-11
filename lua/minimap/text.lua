local utils = require('minimap.utils')
local config = require('minimap.config').get_config()

local M = {}

local function is_whitespace(chr)
  return chr == " " or chr == "\t" or chr == ""
end

local function coord_to_flag(x, y)
  x = x - 1
  y = y - 1
  if y % 4 < 3 then
    return math.pow(2, y % 4) * (x % 2 == 0 and 1 or 8)
  end
  return x % 2 == 0 and 64 or 128
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

return M
