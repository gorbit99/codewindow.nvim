local M = {}

local config = {
  active_in_terminals = false,
  auto_enable = false,
  exclude_filetypes = {},
  keybindings = false,
  max_minimap_height = nil,
  minimap_width = 20,
  use_lsp = true,
  use_treesitter = true,
  width_multiplier = 4,
  z_index = 1,
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
