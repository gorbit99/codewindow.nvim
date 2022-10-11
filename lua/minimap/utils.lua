local M = {}

local utf8 = require('lua-utf8')

local config = require('minimap.config').get_config()

function M.buf_to_minimap(x, y)
  local minimap_x = math.floor((x - 1) / config.width_multiplier / 2) + 1
  local minimap_y = math.floor((y - 1) / 4) + 1
  return minimap_x, minimap_y
end

function M.flag_to_char(flag)
  return utf8.char(0x2800 + flag)
end

return M
