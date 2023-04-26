local M = {}

local config = {
  active_in_terminals = false,
  auto_enable = false,
  exclude_filetypes = {},
  max_lines = nil,
  max_minimap_height = nil,
  minimap_width = 20,
  use_lsp = true,
  use_treesitter = true,
  use_git = true,
  width_multiplier = 4,
  z_index = 1,
  show_cursor = true,
  window_border = 'single',
  relative = 'win',
  events = { 'TextChanged', 'InsertLeave', 'DiagnosticChanged', 'FileWritePost' }
}

function M.get()
  return config
end

function M.setup(new_config)
  if new_config == nil then
    return config
  end
  for k, v in pairs(new_config) do
    config[k] = v
  end
  return config
end

return M
