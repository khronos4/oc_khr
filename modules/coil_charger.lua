local drawing = require("khrd.drawing")
local core = require("khrd.core")
local component = require("component")
local sides = require("sides")

local module = {
  name = "RC Coil Charger"
}

Mod = {}
Mod.__index = Mod

function Mod.create(ctx, cfg)
  local data = {}
  setmetatable(data, Mod)
  data.ctx = ctx
  data.cfg = cfg.mod.coil_charger
  for group, setting in pairs(data.cfg) do
    setting.charging = false
    setting.discharging = false
    setting.pulse = true
  end 
  return data
end

function Mod:draw_view(menu, x, y, w, h)
  drawing.text_centered(self.ctx, x, y, w, 0, "RC Coil Charger")

  local i = 0
  for group, setting in pairs(self.cfg) do
    self.ctx.set(x, y + 2 + i, group .. ": ")
    if setting.charging then
      self.ctx.setForeground(0xFF0000)
    elseif setting.discharging then
      self.ctx.setForeground(0x00FF00)
    end
    self.ctx.set(x + 10, y + 2 + i, "Charge min: " .. setting.min .. ", max: " .. setting.max)
    self.ctx.setForeground(0xFFFFFF)
    self.ctx.set(x + 30, y + 2 + i, "Select Group - [N/P], Charge - [C], Discharge - [D]")
    i = i + 1

    for addr, coil in pairs(self:get_coils(group)) do
      local info = "<not found>"
      if coil then
        info = coil.getName() .. "  Charge: " .. tostring(coil.getEnergy() / 1000000) .. " M, "
        --info = info .. "Power: " .. tostring(coil.getPower()) .. ", Ratio: " .. tostring(coil.getRatio())
      end
      self.ctx.set(x, y + 2 + i, "  " .. addr .. "   " .. info)
      i = i + 1
    end
    i = i + 1
  end
end

function Mod:key_down(menu, char, code)
  if char == string.byte("c") then
    for group, setting in pairs(self.cfg) do
      local rs = self:get_charger_redstone(group)
      if not rs then
        core.log_error("Redstone control for " .. group .. " not found")
      else
        if setting.charging then
          rs.disable()
          setting.charging = false
        else
          rs.enable()
          setting.charging = true
        end
      end
    end
  elseif char == string.byte("d") then

  end
end

function Mod:key_up(menu, char, code)
end

function Mod:update()
  for group, setting in pairs(self.cfg) do
    for addr, coil in pairs(self:get_coils(group)) do
      if coil and setting.charging then
        local energy = coil.getEnergy() / 1000000
        if energy >= setting.max then
          local rs = self:get_charger_redstone(group)
          if rs then
            core.log_info("Coil group " .. group .. " charged")
            rs.disable()
          else
            core.log_error("Unable to stop charging of group " .. group)
          end
        end
      end
    end
  end
end

function Mod:get_coils(group)
  local coils = {}
  for address, component_type in component.list("AdvancedGears") do
    for _, addr in ipairs(self.cfg[group].coils) do
      if string.sub(address, 1, string.len(addr)) == addr then
        coils[address] = component.proxy(address)
      end
    end
  end
  return coils
end

function Mod:get_charger_redstone(group)
  local addr = self.cfg[group].charger_rs.addr
  local side = self.cfg[group].charger_rs.side

  if not addr then 
    core.log_error("Invalid redstone I/O address of group " .. group)
    return nil 
  end
  if not sides[side] then
  core.log_error("Invalid redstone I/O side of group " .. group) 
    return nil 
  end

  local rs = component.proxy(addr)
  if not rs then 
    core.log_error("Redstone I/O group " .. group .. " was not found by address " .. addr)
    return nil 
  end

  return {
    enable = function() rs.setOutput(sides[side], 255) end,
    disable = function() rs.setOutput(sides[side], 0) end,
  }
end


function module.init(ctx, cfg)
  return Mod.create(ctx, cfg)
end

return module
