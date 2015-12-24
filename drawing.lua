local unicode = require("unicode")


local module = {}
module.symbols = {
  h_line = unicode.char(0x2501), -- ━
  v_line = unicode.char(0x2503), -- ┃
  corner_1 = unicode.char(0x2513), -- ┓
  corner_2 = unicode.char(0x2517), -- ┗
  corner_3 = unicode.char(0x251B), -- ┛
  corner_4 = unicode.char(0x250F), -- ┏
  h_split_left = unicode.char(0x2523), -- ┣
  h_split_right = unicode.char(0x252B), -- ┫
  arrow_right = unicode.char(0x2BC8), -- ⯈
  arrow_left = unicode.char(0x2BC7), -- ⯇
  arrow_up = unicode.char(0x2BC5), -- ⯅
  arrow_down = unicode.char(0x2BC6), -- ⯆
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

function module.h_split(ctx, x, y, w)
  ctx.fill(x, y, w, 1, " ")
  ctx.set(x, y, module.symbols.h_split_left)
  ctx.set(x + w, y, module.symbols.h_split_right)
  if w > 1 then
    ctx.fill(x + 1, y, w - 1, 1, module.symbols.h_line)
  end
end


function module.arrow(ctx, x, y, id)
  if id == 0 then
    ctx.set(x, y, module.symbols.arrow_right)
  elseif id == 1 then
    ctx.set(x, y, module.symbols.arrow_left)
  elseif id == 2 then
    ctx.set(x, y, module.symbols.arrow_up)
  elseif id == 3 then
    ctx.set(x, y, module.symbols.arrow_down)
  end
end

function module.text_centered(ctx, x, y, w, h, text)
  local offset = (w - string.len(text)) / 2
  ctx.set(x + offset, y + h / 2, text)
end

return module
