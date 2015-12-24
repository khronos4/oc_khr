local drawing = require("khrd.drawing")
local component = require("component")

local module = {
  name = "Coil Charger"
}

Mod = {}
Mod.__index = Mod

function Mod.create(ctx, cfg)
  local data = {}
  setmetatable(data, Mod)
  data.ctx = ctx
  data.cfg = cfg.mod.coil_charger
  return data
end

function Mod:draw_view(menu, x, y, w, h)
  drawing.text_centered(self.ctx, x, y, w, 0, "Coil Charger")

  local i = 0
  for addr, coil in self:get_coils() do
    self.ctx.set(x, y + 2 + i, addr .. " " .. tostring(coil.getEnergy() / 1000000) .. " M")
    i = i + 1
  end
end

function Mod:on_key_down(menu, char, code)
end

function Mod:on_key_up(menu, char, code)
end

function Mod:update()
end

function Mod:get_coils()
  local coils = {}
  for address, component_type in component.list("AdvancedGears") do
    for addr in self.cfg.coils do
      if string.sub(address, 1, string.len(addr)) == addr then
        coils[address] = component.proxy(address)
      end
    end
  end
  return coils
end


function module.init(ctx, cfg)
  return Mod.create(ctx, cfg)
end

return module
