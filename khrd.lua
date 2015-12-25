local core = require("khrd.core")
local util = require("khrd.util")
local drawing = require("khrd.drawing")

local component = require("component")
local event = require("event")
local gpu = component.gpu
local term = require("term")
local unicode = require("unicode")
local keyboard = require("keyboard")
local computer = require("computer")
local sides = require("sides")

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

local khrd_modules = {}


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

  data.menu = {
    {name = "Information", draw = "draw_info_menu"},
    {name = "Components", draw = "draw_components_menu", onenter = "components_sub"},
  }

  for name, mod in pairs(khrd_modules) do
    local mod_instance = mod.init(ctx, khrd_config)
    data.menu[#data.menu + 1] = {name = mod.name, mod = mod_instance, draw = "draw_mod"}
  end

  data.menu_state = util.stack()
  data.menu_state:push(1)
  return data
end

function UI:current_menu()
  local menu = self.menu
  for i = 1, self.menu_state:getn() - 1 do
    local id = self.menu_state:get()[i]
    if menu[id].menu then
      menu = menu[id].menu
    else
      return nil
    end
  end
  return menu
end

function UI:draw()
  drawing.box(self.ctx, self.x, self.y, 20, self.h - 1)
  drawing.box(self.ctx, self.x + 21, self.y, self.w - 22, self.h - 1)
  drawing.h_split(self.ctx, self.x + 21, self.y + 2, self.w - 22)

  local offset = 0
  local menu = self:current_menu()
  local draw_fn = nil

  for i=1, #menu do
    if self.menu_state:last() == i then
      drawing.arrow(self.ctx, self.x + 1, self.y + i + offset, 0)
      draw_fn = menu[i].draw
    end
    self.ctx.set(self.x + 3, self.y + i + offset, string.sub(menu[i].name, 0, 18))
  end

  if draw_fn then
    self[draw_fn](self, menu[self.menu_state:last()], self.x + 22, self.y + 1, self.w - 23, self.h - 2)
  end
end

function UI:key_down(char, code)
  local menu = self:current_menu()

  local id = self.menu_state:last()
  if code == keyboard.keys.up then
    if id > 1 then
      id = id - 1 
      self.menu_state:pop()
      self.menu_state:push(id)
      self:update_menu_selection()
    end
  elseif code == keyboard.keys.down then
    if id < #menu then
      id = id + 1
      self.menu_state:pop()
      self.menu_state:push(id)
      self:update_menu_selection()
     end
  elseif code == keyboard.keys.left then
  elseif code == keyboard.keys.right then
  elseif code == keyboard.keys.enter then
    enter_fn = menu[id].onenter
    if enter_fn then
      self[enter_fn](self, menu[id], id)
    end
  end
  if menu[id].mod then
    menu[id].mod:key_down(menu[id], char, code
  end
end

function UI:key_up(char, code)
  if menu[id].mod then
    menu[id].mod:key_up(menu[id], char, code
  end
end

function UI:update_menu_selection()
end

function UI:draw_mod(menu, x, y, w, h)
  if menu.mod then
    menu.mod:draw_view(menu, x, y, w, h)
  end
end

function UI:draw_info_menu(menu, x, y, w, h)
  drawing.text_centered(self.ctx, x, y, w, 0, "Information")

  local h_offset = 12
  self.ctx.set(x, y + 2, "Uptime: ") self.ctx.set(x + h_offset, y + 2, tostring(computer.uptime()))
  self.ctx.set(x, y + 3, "Address: ") self.ctx.set(x + h_offset, y + 3, computer.address())
  self.ctx.set(x, y + 4, "Memory: ") self.ctx.set(x + h_offset, y + 4, tostring(computer.freeMemory()) .. " / " .. tostring(computer.totalMemory()))
  self.ctx.set(x, y + 5, "Energy: ") self.ctx.set(x + h_offset, y + 5, tostring(computer.energy()) .. " / " .. tostring(computer.maxEnergy()))
end

function UI:draw_components_menu(menu, x, y, w, h)
  drawing.text_centered(self.ctx, x, y, w, 0, "Components")
  drawing.text_centered(self.ctx, x, y, w, h, "Press ENTER to view components list")
end

function UI:draw_component_menu(menu, x, y, w, h)
  local caption = menu.component[2].name .. " " .. menu.component[1]
  drawing.text_centered(self.ctx, x, y, w, 0, caption)

  self.ctx.set(x, y + 2, "Type: " .. menu.component[2].type)
  self.ctx.set(x, y + 3, "Methods/fields: ")

  local i = 0
  for name, value in pairs(menu.component[2].methods) do
    local description = name .. " " .. tostring(value)
    self.ctx.set(x + 2, y + 4 + i, string.sub(description, 0, w - 2))
    i = i + 1
    if i == h then
      break
    end
  end
end


function UI:components_sub(menu, id)
  menu.menu = {
    {name = "..", onenter = "go_back"}
  }
  local sorted = {}
  local components = core.collect_components()
  for k, v in pairs(components) do
    sorted[#sorted + 1] = {k, v}
  end

  function compare(a, b)
    return a[2].name < b[2].name
  end

  table.sort(sorted, compare)
  for i = 1, #sorted do
    menu.menu[#menu.menu + 1] = {
      name = sorted[i][2].name,
      component = sorted[i],
      draw = "draw_component_menu"
    }
  end

  self.menu_state:push(1)
  self:update_menu_selection()
end

function UI:go_back(menu, id)
  self.menu_state:pop()
  self:update_menu_selection()
end


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
  khrd_modules = core.load_mods()
  khr_reset_redstone()
end

local function khr_shutdown()
  khr_reset_redstone()
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

  khrd_ui = UI.create(gpu, 1, 3, khrd_config.gpu.w, khrd_config.gpu.h - 3 - khrd_config.log.max_lines)

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
  local num_lines = math.min(khrd_config.log.max_lines, #log)
  local offset = #log - num_lines
  for i = 1, num_lines do
    gpu.fill(1, khrd_config.gpu.h - 1 - khrd_config.log.max_lines + i, old_gpu_settings.w, 1, " ")
    gpu.set(1, khrd_config.gpu.h - 1 - khrd_config.log.max_lines + i, unicode.char(0x2B24))
    if log[offset + i][1] then
      gpu.setForeground(0xFF0000)
    end
    gpu.set(3, khrd_config.gpu.h - 1 - khrd_config.log.max_lines + i, log[offset + i][2])
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
