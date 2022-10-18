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

local function most_commons(highlight) local count_table = {}

  for _, v in ipairs(highlight) do
    if not count_table[v] then
      count_table[v] = 0
    end
    count_table[v] = count_table[v] + 1
  end
  local max = 0
  for _, count in pairs(count_table) do
    if count > max then
      max = count
    end
  end

  local result = {}
  for entry, count in pairs(count_table) do
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

  local minimap_width = config.minimap_width
  local width_multiplier = config.width_multiplier

  local text_highlights = {}
  for _ = 1, #lines do
    local line = {}
    for _ = 1, minimap_width * width_multiplier * 2 do
      table.insert(line, {})
    end
    table.insert(text_highlights, line)
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

    local iter = query:query():iter_captures(root, buf_highlighter.bufnr, 0, #lines + 1)

    for capture, node, _ in iter do
      local hl = query.hl_cache[capture]
      if hl then
        local c = query._query.captures[capture]
        if c ~= nil then
          local start_row, start_col, end_row, end_col = ts_utils.get_vim_range({ ts_utils.get_node_range(node) },
            buffer)

          for y = start_row, end_row do
            for x = start_col, math.min(end_col, #text_highlights[y]) do
              table.insert(text_highlights[y][x], c);
            end
          end
        end
      end
    end
  end, true)

  local highlights = {}
  for _ = 1, math.floor(#lines / 4) + 1 do
    local line = {}
    for _ = 1, minimap_width do
      table.insert(line, {})
    end
    table.insert(highlights, line)
  end

  for y = 1, #text_highlights do
    for x = 1, #text_highlights[y] do
      if text_highlights[y][x] ~= '' then
        local minimap_x, minimap_y = utils.buf_to_minimap(x, y)

        for _, v in ipairs(text_highlights[y][x]) do
          table.insert(highlights[minimap_y][minimap_x], v)
        end
      end
    end
  end

  for y = 1, #highlights do
    for x = 1, #highlights[y] do
      highlights[y][x] = most_commons(highlights[y][x])
    end
  end

  return highlights
end

function M.apply_highlight(highlights, buffer)
  create_hl_namespaces(buffer)

  for y = 1, #highlights do
    for x = 1, #highlights[y] do
      for _, group in ipairs(highlights[y][x]) do
        vim.api.nvim_buf_add_highlight(buffer, hl_namespace, '@' .. group, y - 1, (x - 1) * 3 + 6, x * 3 + 6)
      end
    end
  end

  for y = 1, #highlights do
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
