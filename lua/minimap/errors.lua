local inspect = require "inspect"
local utils   = require "minimap.utils"
local M       = {}

function M.get_lsp_errors(buffer)
  local lines = vim.api.nvim_buf_get_lines(buffer, 0, -1, true)
  local error_lines = {}
  for _ = 1, #lines do
    table.insert(error_lines, { warn = false, err = false })
  end

  local errors = vim.diagnostic.get(buffer, { severity = { min = vim.diagnostic.severity.WARN } })
  for _, v in ipairs(errors) do
    if v.severity == vim.diagnostic.severity.WARN then
      error_lines[v.lnum + 1].warn = true
    else
      error_lines[v.lnum + 1].err = true
    end
  end

  local error_text = {}
  for i = 1, #error_lines + 3, 4 do
    local err_flag = 0
    local warn_flag = 0

    local flags = { 1, 2, 4, 64 }

    for di = 0, 3 do
      if error_lines[i + di] then
        if error_lines[i + di].err then
          err_flag = err_flag + flags[di + 1]
        end
        if error_lines[i + di].warn then
          warn_flag = warn_flag + flags[di + 1]
        end
      end
    end

    local err_char = utils.flag_to_char(err_flag)
    local warn_char = utils.flag_to_char(warn_flag)

    table.insert(error_text, err_char .. warn_char)
  end

  return error_text
end

return M
