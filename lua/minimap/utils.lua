local M = {}

local utf8 = require('lua-utf8')

local config = require('minimap.config').get_config()

function M.buf_to_minimap(x, y)
  local minimap_x = math.floor((x - 1) / config.width_multiplier / 2) + 1
  local minimap_y = math.floor((y - 1) / 4) + 1
  return minimap_x, minimap_y
end

local braille_chars = "⠀⠁⠂⠃⠄⠅⠆⠇⡀⡁⡂⡃⡄⡅⡆⡇⠈⠉⠊⠋⠌⠍⠎⠏⡈⡉⡊⡋⡌⡍⡎⡏"
    ..
    "⠐⠑⠒⠓⠔⠕⠖⠗⡐⡑⡒⡓⡔⡕⡖⡗⠘⠙⠚⠛⠜⠝⠞⠟⡘⡙⡚⡛⡜⡝⡞⡟" ..
    "⠠⠡⠢⠣⠤⠥⠦⠧⡠⡡⡢⡣⡤⡥⡦⡧⠨⠩⠪⠫⠬⠭⠮⠯⡨⡩⡪⡫⡬⡭⡮⡯" ..
    "⠰⠱⠲⠳⠴⠵⠶⠷⡰⡱⡲⡳⡴⡵⡶⡷⠸⠹⠺⠻⠼⠽⠾⠿⡸⡹⡺⡻⡼⡽⡾⡿" ..
    "⢀⢁⢂⢃⢄⢅⢆⢇⣀⣁⣂⣃⣄⣅⣆⣇⢈⢉⢊⢋⢌⢍⢎⢏⣈⣉⣊⣋⣌⣍⣎⣏" ..
    "⢐⢑⢒⢓⢔⢕⢖⢗⣐⣑⣒⣓⣔⣕⣖⣗⢘⢙⢚⢛⢜⢝⢞⢟⣘⣙⣚⣛⣜⣝⣞⣟" ..
    "⢠⢡⢢⢣⢤⢥⢦⢧⣠⣡⣢⣣⣤⣥⣦⣧⢨⢩⢪⢫⢬⢭⢮⢯⣨⣩⣪⣫⣬⣭⣮⣯" ..
    "⢰⢱⢲⢳⢴⢵⢶⢷⣰⣱⣲⣳⣴⣵⣶⣷⢸⢹⢺⢻⢼⢽⢾⢿⣸⣹⣺⣻⣼⣽⣾⣿"

function M.flag_to_char(flag)
  return braille_chars:sub(flag * 3 + 1, (flag + 1) * 3)
end

function M.get_top_line(window)
  if window then
    return vim.fn.line('w0', window)
  end
  return vim.fn.line('w0')
end

function M.get_bot_line(window)
  if window then
    return vim.fn.line('w$', window)
  end
  return vim.fn.line('w$')
end

function M.get_buf_height(buffer)
  return vim.api.nvim_buf_line_count(buffer)
end

function M.scroll_window(window, amount)
  if not vim.api.nvim_win_is_valid(window) then
    return
  end

  vim.api.nvim_win_call(window, function()
    if amount > 0 then
      local botline = M.get_bot_line()
      local buffer = vim.api.nvim_win_get_buf(window)
      local height = M.get_buf_height(buffer)
      if botline >= height then
        return
      end
      local max_move_down = math.min(amount, height - botline)
      vim.cmd(string.format('execute "normal! %d\\<C-e>"', max_move_down))
    else
      amount = -amount
      if window == nil then
        return
      end
      local topline = M.get_top_line()
      if topline <= 1 then
        return
      end
      local max_move_up = math.min(amount, topline - 1)
      vim.cmd(string.format('execute "normal! %d\\<C-y>"', max_move_up))
    end
  end)
end

return M
