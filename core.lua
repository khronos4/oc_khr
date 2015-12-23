-- based on:
--   https://github.com/MightyPirates/OpenComputers/blob/master-MC1.7.10/src/main/resources/assets/opencomputers/loot/OPPM/oppm.lua

local component = require("component")
local event = require("event")
local fs = require("filesystem")
local process = require("process")
local serial = require("serialization")
local shell = require("shell")
local term = require("term")

local module = {}

-- collect connected components
function module.collect_components()
  local components = {}
  for address, name in component.list() do
    local component_info = {}
    local methods = {}
    local proxy = component.proxy(address)

    for name, member in pairs(proxy) do
      if type(member) == "table" or type(member) == "function" then
        methods[name] = component.doc(address, name)
      end
    end

    component_info['name'] = name
    component_info['type'] = component.type(address)
    component_info['methods'] = methods
    component_info['open'] = function() return component.proxy(address) end

    components[address] = component_info
  end
  return components
end

-- logging
function module.log_info(text, ...)
  print(text, args)
end

-- logging
function module.log_error(text, ...)
  io.stderr:write(text, args)
end

function module.load_config()
  path = "/etc/khrd.cfg"
  if not fs.exists(path) then
    local tProcess = process.running()
    path = fs.concat(fs.path(shell.resolve(tProcess)),"/etc/khrd.cfg")
  end

  if not fs.exists(fs.path(path)) then
    fs.makeDirectory(fs.path(path))
  end
  if not fs.exists(path) then
    return {-1}
  end
  local file,msg = io.open(path,"rb")
  if not file then
    module.log_error("Error while trying to read file at "..path..": "..msg)
    return
  end
  local sPacks = file:read("*a")
  file:close()
  return serial.unserialize(sPacks) or {-1}
end

return module