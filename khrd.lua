local core = require("khrd.core")
local util = require("khrd.util")

local component = require("component")
local event = require("event")
local unicode = require("unicode")
local computer = require("computer")

-- configuration
local khrd_config = core.load_config()
local khrd_modules = {}

-- pcall wrapper with tracebacks
local function khr_call(fn, ...)
  return core.call(fn, ...)
end

local function khr_reset_redstone()
  for address, component_type in component.list("redstone") do
    local p = component.proxy(address)
    for i = 0, 5 do
      p.setOutput(i, 0)
    end
  end
end

-- initialize common subsystems
local function khr_initialize()
  core.log_info("Initializing daemon")
  khr_reset_redstone()
  for name, mod in pairs(core.load_mods(khrd_config)) do
    local mod_instance = mod.init(khrd_config)
    khrd_modules[name] = mod_instance
  end
end

local function khr_shutdown()
  khrd_modules = {}
  khrd_config = {}
  khr_reset_redstone()
  core.log_info("Terminated")
end

function start(...)
  khr_initialize()
end

function stop(...)
  khr_shutdown()
end

function status(...)
end