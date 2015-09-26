local core = require("khrd.core")

local component = require("component")
local event = require("event")
local gpu = component.gpu


-- initialize common subsystems
local function khr_initialize()
  core.log_info("Initializing daemon")
end

local function khr_shutdown()
end

-- initializing UI
local function khr_initialize_visual()
  core.log_info("Initializing display")
end

local function khr_restore_visual()
end

function khr_handle_event(event_id, ...)
  if event_id then -- can be nil if no event was pulled for some time
    -- components
    if event_id == "component_added" then
      address, component_type = args
    elseif event_id == "component_removed" then
      address, component_type = args

    -- keyboard events
    elseif event_id == "key_up" then
      address, char, code, player = args
      if char == string.byte(" ") then
        return false
      end
    end 
  end
  return true
end

-- main event loop
local function khr_event_loop()
  core.log_info("Entering event loop")
  local running = true
  while running do
    status, result = khr_call(khr_handle_event, event.pull()) -- sleeps until an event is available, then process it
    if status then
      running = result
    end
  end
end

-- pcall wrapper with tracebacks
local function khr_call(fn, ...)
  local status, data = pcall(fn, args)
  if status then
    return true, data
  end
  core.log_error("Error: " .. tostring(data))
  core.log_error(debug.traceback())
  return false, data
end

local function khr_run()
  local status, result = khr_call(khr_initialize)
  if not status then return end
  
  if gpu != nil then
    local status, result = khr_call(khr_initialize_visual)
    if not status then 
      khr_call(khr_shutdown)
      return
    end
  end
  
  khr_call(khr_event_loop)
  if gpu ~= nil then
    khr_call(khr_restore_visual)
  end
  khr_call(khr_shutdown)
end

-- running
khr_run()