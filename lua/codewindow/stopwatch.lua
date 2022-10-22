local M = {}

local stopwatches = {}

function M.start(name)
  local stopwatch = {}

  if stopwatches[name] == nil then
    stopwatches[name] = { time_sum = 0, runs = 0 }
  end

  stopwatches[name].current_start = os.clock()

  function stopwatch.stop()
    stopwatches[name].time_sum = stopwatches[name].time_sum + os.clock() - stopwatches[name].current_start
    stopwatches[name].runs = stopwatches[name].runs + 1
  end

  return stopwatch
end

local function print_specific(name)
  if name then
    if stopwatches[name] == nil or stopwatches[name].runs == 0 then
      print(name .. ": " .. "0")
      return
    end
    print(name .. ": " .. (stopwatches[name].time_sum / stopwatches[name].runs))
  end
end

function M.print(name)
  if name then
    print_specific(name)
  end

  for k, _ in pairs(stopwatches) do
    print_specific(k)
  end
end

return M
