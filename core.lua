local util = require("khrd.util")

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
        local doc = component.doc(address, name)
        if not doc then doc = "" end
        methods[name] = doc
      else
        methods[name] = ""
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

module.log = {}
module.log_to_term = true

-- logging
function module.log_info(...)
  local str = ""
  local arg={...}
  for i,v in ipairs(arg) do
    str = str .. tostring(v) .. " "
  end
  module.log[#module.log + 1] = {false, str}
  if module.log_to_term then
    print(str)
  end
  fs.makeDirectory("/var/log/")
  local f = fs.open("/var/log/khrd.log", "a")
  f:write("[I] " .. str .. "\n")
  f:close()
end

-- logging
function module.log_error(...)
  local str = ""
  local arg={...}
  for i,v in ipairs(arg) do
    str = str .. tostring(v) .. " "
  end
  module.log[#module.log + 1] = {true, str}
  if module.log_to_term then
    io.stderr:write(str .. "\n")
  end
  fs.makeDirectory("/var/log/")
  local f = fs.open("/var/log/khrd.log", "a")
  f:write("[E] " .. str .. "\n")
  f:close()
end

function module.get_log()
  return module.log
end

function module.enable_term_log()
  module.log_to_term = true
end

function module.disable_term_log()
  module.log_to_term = false
end

function module.load_config()
  -- based on code from:
  --   https://github.com/MightyPirates/OpenComputers/blob/master-MC1.7.10/src/main/resources/assets/opencomputers/loot/OPPM/oppm.lua
  path = "/etc/khrd.cfg"
  if not fs.exists(path) then
    local tProcess = process.running()
    path = fs.concat(fs.path(shell.resolve(tProcess)), "/etc/khrd.cfg")
  end

  if not fs.exists(fs.path(path)) then
    fs.makeDirectory(fs.path(path))
  end
  if not fs.exists(path) then
    return {-1}
  end
  local file,msg = io.open(path,"rb")
  if not file then
    module.log_error("Error while trying to read file at " .. path .. ": " .. msg)
    return
  end
  local sPacks = file:read("*a")
  file:close()
  return serial.unserialize(sPacks) or {-1}
end

function module.load_mods()
  path = "/usr/lib/khrd/modules/"
  local it, msg = fs.list(path)
  if not it then
    module.log_error(msg)
    return {}
  end

  result = {}
  while true do
    local mod = it()
    if not mod then break end
    if not fs.isDirectory(mod) then
      module.log_info("Loading " .. mod)
      mod_data, status = loadfile(path .. mod)
      if not status then
        result[mod] = mod_data()
      else
        module.log_error(status)
      end
    end
  end

  return result
end

function module.call(fn, ...)
  local status, data = xpcall(fn, function(err) return debug.traceback(err) end, ...)
  if status then
    return true, data
  end
  local lines = util.split(data, "\n")
  for i = 1, #lines do
    module.log_error(string.gsub(lines[i], "\t", " "))
  end
  return false, data
end

return module
