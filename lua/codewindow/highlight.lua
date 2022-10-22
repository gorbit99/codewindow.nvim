local utils = require('codewindow.utils')
local M     = {}

local hl_namespace
local underline_namespace
local diagnostic_namespace

local function create_hl_namespaces(buffer)
  hl_namespace = vim.api.nvim_create_namespace("codewindow.highlight")
  underline_namespace = vim.api.nvim_create_namespace("codewindow.underline")
  diagnostic_namespace = vim.api.nvim_create_namespace("codewindow.diagnostic")
  vim.api.nvim_buf_clear_namespace(buffer, hl_namespace, 0, -1)
  vim.api.nvim_buf_clear_namespace(buffer, underline_namespace, 0, -1)
  vim.api.nvim_buf_clear_namespace(buffer, diagnostic_namespace, 0, -1)
end

local function most_commons(highlight)
  local max = 0
  for _, count in pairs(highlight) do
    if count > max then
      max = count
    end
  end

  local result = {}
  for entry, count in pairs(highlight) do
    if count == max then
      table.insert(result, entry)
    end
  end

  return result
end

function M.extract_highlighting(buffer, lines)
  local highlighter = require('vim.treesitter.highlighter')
  local ts_utils    = require('nvim-treesitter.ts_utils')

  if not vim.api.nvim_buf_is_valid(buffer) then
    return
  end
  local config = require('codewindow.config').get()

  local buf_highlighter = highlighter.active[buffer]

  if buf_highlighter == nil then
    return
  end

  local line_count = #lines
  local minimap_width = config.minimap_width
  local minimap_height = math.ceil(line_count / 4)
  local width_multiplier = config.width_multiplier
  local minimap_char_width = minimap_width * width_multiplier * 2

  local highlights = {}
  for _ = 1, minimap_height do
    local line = {}
    for _ = 1, minimap_width do
      table.insert(line, {})
    end
    table.insert(highlights, line)
  end

  buf_highlighter.tree:for_each_tree(function(tstree, tree)
    if not tstree then
      return
    end

    local root = tstree:root()

    local query = buf_highlighter:get_query(tree:lang())

    if not query:query() then
      return
    end

    local iter = query:query():iter_captures(root, buf_highlighter.bufnr, 0, line_count + 1)

    for capture, node, _ in iter do
      local hl = query.hl_cache[capture]
      if hl then
        local c = query._query.captures[capture]
        if c ~= nil then
          local start_row, start_col, end_row, end_col = ts_utils.get_vim_range({ ts_utils.get_node_range(node) },
            buffer)

          for y = start_row, end_row do
            for x = start_col, math.min(end_col, minimap_char_width) do
              local minimap_x, minimap_y = utils.buf_to_minimap(x, y)
              highlights[minimap_y][minimap_x][c] = (highlights[minimap_y][minimap_x][c] or 0) + 1
            end
          end
        end
      end
    end
  end, true)

  for y = 1, minimap_height do
    for x = 1, minimap_width do
      highlights[y][x] = most_commons(highlights[y][x])
    end
  end

  return highlights
end

local function contains_group(cell, group)
  for i, v in ipairs(cell) do
    if v == group then
      return i
    end
  end
  return nil
end

function M.apply_highlight(highlights, buffer)
  create_hl_namespaces(buffer)

  local minimap_height = #highlights
  local minimap_width = #highlights[1]

  for y = 1, minimap_height do
    for x = 1, minimap_width do
      for _, group in ipairs(highlights[y][x]) do
        if group ~= '' then
          local end_x = x
          while end_x < minimap_width do
            local pos = contains_group(highlights[y][end_x + 1], group)
            if not pos then
              break
            end
            end_x = end_x + 1
            highlights[y][x][pos] = ''
          end
          vim.api.nvim_buf_add_highlight(buffer, hl_namespace, '@' .. group, y - 1, (x - 1) * 3 + 6,
            end_x * 3 + 6)
        end
      end
    end
  end

  for y = 1, minimap_height do
    vim.api.nvim_buf_add_highlight(buffer, diagnostic_namespace, "DiagnosticSignError", y - 1, 0, 3)
    vim.api.nvim_buf_add_highlight(buffer, diagnostic_namespace, "DiagnosticSignWarn", y - 1, 3, 6)
  end
end

function M.display_screen_bounds(window)
  if underline_namespace == nil then
    return
  end
  vim.api.nvim_buf_clear_namespace(window.buffer, underline_namespace, 0, -1)

  local topline = utils.get_top_line(window.parent_win)
  local botline = utils.get_bot_line(window.parent_win)

  local difference = math.ceil((botline - topline) / 4) + 1

  local top_y = math.floor(topline / 4)

  if top_y > 0 then
    vim.api.nvim_buf_add_highlight(window.buffer, underline_namespace, "Underlined", top_y - 1, 6, -1)
  end
  local bot_y = top_y + difference - 1
  local buf_height = vim.api.nvim_buf_line_count(window.buffer)
  if bot_y > buf_height - 1 then
    bot_y = buf_height - 1
  end
  if bot_y < 0 then
    return
  end
  vim.api.nvim_buf_add_highlight(window.buffer, underline_namespace, "Underlined", bot_y, 6, -1)

  local center = math.floor((top_y + bot_y) / 2) + 1
  vim.api.nvim_win_set_cursor(window.window, { center, 0 })
end

return M
