local core = require("khrd.core")

local component = require("component")
local event = require("event")
local gpu = component.gpu
local term = require("term")

-- configuration
local khrd_config = core.load_config()
local old_gpu_settings = {
  w = 0,
  h = 0
}

local key_handlers = {
  [" "] = {
    terminate = true,
    description = "SPACE - exit"
  }
}


-- initialize common subsystems
local function khr_initialize()
  core.log_info("Initializing daemon")
  --print(core.load_config())
end

local function khr_shutdown()
  core.log_info("Terminated")
end

-- initializing UI
local function khr_initialize_visual()
  core.log_info("Initializing display")
  local _w, _h = gpu.getResolution()
  old_gpu_settings.w = _w
  old_gpu_settings.h = _h
  gpu.setResolution(khrd_config.gpu.w, khrd_config.gpu.h)
  gpu.fill(1, 1, khrd_config.gpu.w, khrd_config.gpu.h, " ") -- clears the screen
end

local function khr_restore_visual()
  gpu.setResolution(old_gpu_settings.w, old_gpu_settings.h)
  gpu.fill(1, 1, old_gpu_settings.w, old_gpu_settings.h, " ")
  term.clear()
end

function khr_handle_event(event_id, ...)
  if event_id then -- can be nil if no event was pulled for some time
    -- components
    if event_id == "component_added" then
      address, component_type = args
      core.log_info("Connected " .. component_type .. " at " .. address)

    elseif event_id == "component_removed" then
      address, component_type = args
      core.log_info("Removed " .. component_type .. " at " .. address)

    -- keyboard events
    elseif event_id == "key_up" then
      address, char, code, player = args
      for k, v in pairs(key_handlers) do
        if char == string.byte(k) then
          if v.callback ~= nil then
            v.callback(player)
          end

          if v.terminate == nil then
            return true
          end

          return not v.terminate
        end
      end
    end 
  end
  return true
end

-- update callback
local function khr_update()
  local offset = 1
  for k, v in pairs(key_handlers) do
    gpu.set(1, offset, key_handlers.description)
    offset = offset + 1
  end
end

-- main event loop
local function khr_event_loop()
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
  core.log_error(tostring(debug.traceback()))
  return false, data
end

local function khr_run()
  local status, result = khr_call(khr_initialize)
  if not status then return end
  
  if gpu ~= nil then
    local status, result = khr_call(khr_initialize_visual)
    if not status then 
      khr_call(khr_shutdown)
      return
    end
  end

  local updateTimer = event.timer(0.5, khr_update, math.huge)
  khr_call(khr_event_loop)
  event.cancel(updateTimer)

  if gpu ~= nil then
    khr_call(khr_restore_visual)
  end
  khr_call(khr_shutdown)
end

-- running
khr_run()
