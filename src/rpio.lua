local gpio_subsystem = '/sys/class/gpio/'
local usedPins = {}

local function write(path, value)
  local f = io.open(path, 'a+')
  f:write(tostring(value))
  f:close()
end

local function read(path)
  local f = io.popen('cat ' .. path, 'r')
  local value = tonumber(f:read('*a'))
  f:close()
  return value
end

local function exists(path)
  local f = io.open(path)
  if f then
    f:close()
    return true
  else
    return false
  end
end

local function ready(device)
  return pcall(function()
    write(device .. 'value', 0)
  end)
end

local function cleanup()
	for i,v in pairs(usedPins) do v:set_direction('in') end
end

return function(which)
  local device = gpio_subsystem .. 'gpio' .. which .. '/'

  if exists(device) then
    write(gpio_subsystem .. 'unexport', which)
  end

  write(gpio_subsystem .. 'export', which)

  while not ready(device) do
    os.execute('sleep 0.001')
  end

	usedPins[which] = {
    set_direction = function(direction)
      write(device .. 'direction', direction)
    end,

    write = function(value)
      write(device .. 'value', value)
    end,

    read = function()
      return read(device .. 'value')
    end
  }

  return usedPins[which]
end
