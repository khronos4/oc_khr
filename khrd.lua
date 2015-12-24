local core = require("khrd.core")

local component = require("component")
local event = require("event")
local gpu = component.gpu
local term = require("term")

-- configuration
local khrd_config = core.load_config()
local old_gpu_settings = {
  w = 0,
  h = 0,
  background = nil,
  foreground = nil
}

local key_handlers = {
  [" "] = {
    terminate = true,
    description = "SPACE - exit"
  }
}


-- pcall wrapper with tracebacks
local function khr_call(fn, ...)
  local status, data = pcall(fn, ...)
  if status then
    return true, data
  end
  core.log_error("Error: " .. tostring(data))
  --core.log_error(debug.traceback())
  return false, data
end



-- initialize common subsystems
local function khr_initialize()
  core.log_info("Initializing daemon")
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
  if khrd_config.gpu.w == nil or khrd_config.gpu.w == 0 then
    khrd_config.gpu.w = _w
  end
  if khrd_config.gpu.h == nil or khrd_config.gpu.h == 0 then
    khrd_config.gpu.h = _h
  end

  core.log_info("Setting resolution to " .. khrd_config.gpu.w .. "x" .. khrd_config.gpu.h)
  gpu.setResolution(khrd_config.gpu.w, khrd_config.gpu.h)
  old_gpu_settings.background = gpu.getBackground()
  old_gpu_settings.foreground = gpu.getForeground()
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, khrd_config.gpu.w, khrd_config.gpu.h, " ") -- clears the screen
end

local function khr_restore_visual()
  gpu.setResolution(old_gpu_settings.w, old_gpu_settings.h)
  gpu.setBackground(old_gpu_settings.background)
  gpu.setForeground(old_gpu_settings.foreground)
  gpu.fill(1, 1, old_gpu_settings.w, old_gpu_settings.h, " ")
  term.clear()
end

function unknown_event()
  -- do nothing if the event wasn't relevant
  return true
end

local khr_event_handlers = setmetatable({}, { __index = function() return unknown_event end })
 
function khr_event_handlers.key_up(address, char, code, player_name)
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
  return true
end

function khr_event_handlers.component_added(address, component_type)
  core.log_info("Connected " .. component_type .. " at " .. address)
  return true
end

function khr_event_handlers.component_removed(address, component_type)
  core.log_info("Removed " .. component_type .. " at " .. address)
  return true
end

function khr_handle_event(event_id, ...)
  if event_id then 
    return khr_event_handlers[event_id](...)
  end
  return true
end


-- update callback
local function khr_update()
  -- draw key descriptions
  local offset = 1
  for k, v in pairs(key_handlers) do
    gpu.set(1, offset, v.description)
    offset = offset + 1
  end

  local num_lines = math.min(4, #core.log)
  local offset = #core.log - num_lines
  for i = 1, num_lines do
    if core.log[offset + i][1] then
      gpu.setForeground(0xFF0000)
    end
    gpu.set(1, khrd_config.gpu.h - 5 + i, core.log[offset + i][2])
    gpu.setForeground(0xFFFFFF)
  end
end

-- use safe call with error logging
local function khr_update_()
  khr_call(khr_update)
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

  local updateTimer = event.timer(0.5, khr_update_, math.huge)
  khr_call(khr_event_loop)
  event.cancel(updateTimer)

  if gpu ~= nil then
    khr_call(khr_restore_visual)
  end
  khr_call(khr_shutdown)
end

-- running
khr_run()
