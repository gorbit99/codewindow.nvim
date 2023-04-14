local M = {}

local utils = require('codewindow.utils')
local fn = vim.fn

function M.parse_git_diff(lines)
  local diff = fn.systemlist({ 'git', 'diff', '-U0', fn.expand('%') })

  if vim.v.shell_error ~= 0 then
    return {}
  end

  local removes = {}
  local adds = {}
  for i = 1, #lines do
    removes[i] = false
    adds[i] = false
  end

  for _, v in ipairs(diff) do
    if v:sub(1, 2) == '@@' then
      local d_start, d_lines, a_start, a_lines = v:match('@@ %-(%d+),(%d+) %+(%d+),?(%d*) @@')

      if a_start ~= nil then
        a_start = tonumber(a_start)
        a_lines = a_lines == "" and 1 or tonumber(a_lines)
        d_start = tonumber(d_start)
        d_lines = tonumber(d_lines)

        for i = a_start, a_start + a_lines - 1 do
          adds[i] = true
        end
        if d_lines ~= 0 then
          removes[d_start] = true
        end
      end
    end
  end

  local git_lines = {}
  local minimap_height = math.ceil(#lines / 4)
  for y = 1, minimap_height do
    local a_flag = 0
    local d_flag = 0
    for dy = 1, 4 do
      local line_y = (y - 1) * 4 + dy
      if adds[line_y] then
        a_flag = a_flag + math.pow(2, dy - 1)
      end
      if removes[line_y] then
        d_flag = d_flag + math.pow(2, dy - 1)
      end
    end

    local a_chr = utils.flag_to_char(a_flag)
    local d_chr = utils.flag_to_char(d_flag)

    git_lines[y] = a_chr .. d_chr
  end

  return git_lines
end

return M
