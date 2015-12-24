local core = require("khrd.core")
local util = require("khrd.util")
local drawing = require("khrd.drawing")

local component = require("component")
local event = require("event")
local gpu = component.gpu
local term = require("term")
local unicode = require("unicode")
local keyboard = require("keyboard")

-- configuration
local khrd_config = core.load_config()
local old_gpu_settings = {
  w = 0, h = 0, background = nil, foreground = nil
}

local key_handlers = {
  [" "] = {
    terminate = true,
    description = "SPACE - exit"
  },
  --["e"] = {
  --  description = "E - log error message",
  --  handler = function() core.log_error("Test error") end
  --}
}


UI = {}
UI.__index = UI

function UI.create(ctx, x, y, w, h)
  local data = {}
  setmetatable(data, UI)
  data.ctx = ctx
  data.x = x
  data.y = y
  data.w = w
  data.h = h

  local components = core.collect_components()
  data.menu = {
    {name = "Information", draw = "draw_info_menu"},
    {name = "Components"},
    {name = "Dummy Menu #1"},
    {name = "Dummy Menu #2"},
    {name = "Dummy Menu #3"}
  }
  data.menu_state = util.stack()
  data.menu_state:push(data.menu[1].name)
  return data
end

function UI:draw()
  drawing.box(self.ctx, self.x, self.y, 20, self.h - 1)
  drawing.box(self.ctx, self.x + 21, self.y, self.w - 22, self.h - 1)
  drawing.h_split(self.ctx, self.x + 21, self.y + 2, self.w - 22)

  local offset = 0
  if self.menu_state:getn() > 1 then
    self.ctx.set(self.x + 3, self.y + i + offset, "..")
    offset = offset + 1
  end

  local menu = self.menu
  local draw_fn = nil

  for i=1, #self.menu do
    if self.menu_state:last() == self.menu[i].name then
      drawing.arrow(self.ctx, self.x + 1, self.y + i + offset, 0)
      draw_fn = self.menu[i].draw
    end
    self.ctx.set(self.x + 3, self.y + i + offset, self.menu[i].name)
  end

  if draw_fn then
    self[draw_fn](self, self.x + 22, self.y + 1, self.w - 23, self.h - 2)
  end
end

function UI:key_down(char, code)
  local id = 0
  for i=1, #self.menu do
    if self.menu_state:last() == self.menu[i].name then
      id = i
      break
    end
  end

  if code == keyboard.keys.up then
    if id > 1 then
      id = id - 1 
      self.menu_state:pop()
      self.menu_state:push(self.menu[id].name)
      self:update_menu_selection()
    end
  elseif code == keyboard.keys.down then
    if id < #self.menu then
      id = id + 1
      self.menu_state:pop()
      self.menu_state:push(self.menu[id].name)
      self:update_menu_selection()
     end
  elseif code == keyboard.keys.left then
  elseif code == keyboard.keys.right then
  elseif code == keyboard.keys.enter then
  end
end

function UI:key_up(char, code)
end

function UI:update_menu_selection()
end

function UI:draw_info_menu(x, y, w, h)
  local caption = "Information"
  local offset = (w - string.len(caption)) / 2
  self.ctx.set(x + offset, y, "Information")
end


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

local khrd_ui = nil

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

  khrd_ui = UI.create(gpu, 1, 3, khrd_config.gpu.w, khrd_config.gpu.h - 3 - 4)

  core.disable_term_log()
end

local function khr_restore_visual()
  gpu.setResolution(old_gpu_settings.w, old_gpu_settings.h)
  gpu.setBackground(old_gpu_settings.background)
  gpu.setForeground(old_gpu_settings.foreground)
  gpu.fill(1, 1, old_gpu_settings.w, old_gpu_settings.h, " ")
  term.clear()

  core.enable_term_log()
  khrd_ui = nil
end

local function khr_redraw()
  -- draw key descriptions
  local offset = 1
  local keys_help = ""
  for k, v in pairs(key_handlers) do
    keys_help = keys_help .. v.description .. " "
    --gpu.set(1, offset, v.description)
    --offset = offset + 1
  end
  gpu.set(1, offset, keys_help)
  offset = offset + 1

  -- display last log lines
  local log = core.get_log()
  local num_lines = math.min(4, #log)
  local offset = #log - num_lines
  for i = 1, num_lines do
    gpu.fill(1, khrd_config.gpu.h - 5 + i, old_gpu_settings.w, 1, " ")
    gpu.set(1, khrd_config.gpu.h - 5 + i, unicode.char(0x2B24))
    if log[offset + i][1] then
      gpu.setForeground(0xFF0000)
    end
    gpu.set(3, khrd_config.gpu.h - 5 + i, log[offset + i][2])
    gpu.setForeground(0xFFFFFF)
  end

  if khrd_ui then
    khrd_ui:draw()
  end
end

function unknown_event()
  return true
end

local khr_event_handlers = setmetatable({}, { __index = function() return unknown_event end })
 
function khr_event_handlers.key_up(address, char, code, player_name)
  if khrd_ui then
    khrd_ui:key_up(char, code)
  end

  for k, v in pairs(key_handlers) do
    if char == string.byte(k) then
      if v.handler ~= nil then
        v.handler(player)
      end

      if v.terminate == nil then
        return true
      end

      return not v.terminate
    end
  end
  return true
end

function khr_event_handlers.key_down(address, char, code, player_name)
  if khrd_ui then
    khrd_ui:key_down(char, code)
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
    local result = khr_event_handlers[event_id](...)
    khr_call(khr_redraw)
    return result
  end
  khr_call(khr_redraw)
  return true
end

-- update callback
local function khr_update()
  -- drawing perfromed for all events
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
