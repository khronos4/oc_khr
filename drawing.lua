local unicode = require("unicode")


local module = {}
module.symbols = {
  h_line = unicode.char(0x2501), -- ━
  v_line = unicode.char(0x2503), -- ┃
  corner_1 = unicode.char(0x2513), -- ┓
  corner_2 = unicode.char(0x2517), -- ┗
  corner_3 = unicode.char(0x251B), -- ┛
  corner_4 = unicode.char(0x250F), -- ┏
  arrow_right = unicode.char(0x2BC8), -- ⯈
}

function module.box(ctx, x, y, w, h)
  ctx.fill(x, y, w, h, " ")
  ctx.set(x, y, module.symbols.corner_4)
  ctx.set(x + w, y, module.symbols.corner_1)
  ctx.set(x, y + h, module.symbols.corner_2)
  ctx.set(x + w, y + h, module.symbols.corner_3)
  if w > 1 then
    ctx.fill(x + 1, y, w - 1, 1, module.symbols.h_line)
    ctx.fill(x + 1, y + h, w - 1, 1, module.symbols.h_line)
  end
  if h > 1 then
    ctx.fill(x, y + 1, 1, h - 1, module.symbols.v_line)
    ctx.fill(x + w, y + 1, 1, h - 1, module.symbols.v_line)
  end
end

return drawing
