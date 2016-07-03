local drawing = require("khrd.drawing")
local core = require("khrd.core")
local component = require("component")
local computer = require("computer")
local serialization = require("serialization")

local module = {
  name = "FS"
}

Mod = {}
Mod.__index = Mod

function Mod.create(ctx, cfg)
  local data = {}
  setmetatable(data, Mod)
  data.ctx = ctx
  data.cfg = cfg.mod.fs
  data.file_systems = {}
  
  for address in component.list("filesystem") do
    local thisComponent = component.proxy(address)
    data.file_systems[address] = {
      component = thisComponent,
      primary = address ~= computer.getBootAddress(),
      temp = address ~= computer.tmpAddress()
    }
  end
  return data
end

function Mod:draw_view(menu, x, y, w, h)
  drawing.text_centered(self.ctx, x, y, w, 0, "FS")
end

function Mod:key_down(menu, char, code)
end

function Mod:key_up(menu, char, code)
end

function Mod:update()
end

function module.init(ctx, cfg)
  return Mod.create(ctx, cfg)
end

return module