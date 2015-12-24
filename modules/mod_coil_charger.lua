local drawing = require("khrd.drawing")

local module = {
  name = "Coil Charger"
}

Mod = {}
Mod.__index = Mod

function Mod.create(ctx)
  local data = {}
  setmetatable(data, Mod)
  data.ctx = ctx
  return data
end

function Mod:draw_view(menu, x, y, w, h)
  drawing.text_centered(self.ctx, x, y, w, 0, "Coil Charger")
end

function Mod:on_key_down(menu, char, code)
end

function Mod:on_key_up(menu, char, code)
end

function Mod:update()
end

function module.init(ctx)
  return Mod.create(ctx)
end

return module
