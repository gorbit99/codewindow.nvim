local config = {
  minimap_width = 20,
  width_multiplier = 5,
}

local M = {}

function M.setup(new_config)
  for k, v in pairs(new_config) do
    config[k] = v
  end
end

function M.get_config()
  return config
end

return M
