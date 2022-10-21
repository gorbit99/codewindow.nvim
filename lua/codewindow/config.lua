local M = {}

local config = {
  minimap_width = 20,
  width_multiplier = 4,
  use_lsp = true,
  use_treesitter = true,
  exclude_filetypes = {},
  z_index = 1,
  max_minimap_height = nil,
  active_in_terminals = false,
}

function M.get()
  return config
end

function M.setup(new_config)
  for k, v in pairs(new_config) do
    config[k] = v
  end
end

return M
