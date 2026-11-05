-- Builds img/<name>.pdf (print) and img/<name>.svg (web) from each
-- img/tikz/<name>.tex. Run from the project root:
--   quarto run img/tikz/build.lua

local system, path = pandoc.system, pandoc.path
local here = path.join({ 'img', 'tikz' })

local function read(file)
  local f = assert(io.open(file, 'rb'))
  local text = f:read('a')
  f:close()
  return text
end

local function write(file, text)
  local f = assert(io.open(file, 'wb'))
  f:write(text)
  f:close()
end

local function long_hex(hex)
  hex = hex:lower()
  return #hex == 3 and (hex:gsub('.', '%0%0')) or hex
end

local colors = {}
for name, hex in read(path.join({ here, 'stil.tex' })):gmatch('\\definecolor{(%w+)}{HTML}{(%x+)}') do
  colors[long_hex(hex)] = name
end

-- Palette colors become theme variables, the hex value stays as fallback
local function theme_colors(tag)
  local styles = {}
  for _, attr in ipairs({ 'fill', 'stroke', 'stop-color' }) do
    for hex in tag:gmatch('%f[%w%-]' .. attr:gsub('%-', '%%-') .. "='%s*#(%x+)%s*'") do
      local name = colors[long_hex(hex)]
      if name then
        styles[#styles + 1] = attr .. ':var(--fig-' .. name .. ',#' .. long_hex(hex) .. ')'
      end
    end
  end
  tag = tag:gsub("(stop%-color=')%s*(#%x+)%s*'", "%1%2'")
  if #styles > 0 then
    tag = tag:gsub('(/?>)$', " style='" .. table.concat(styles, ';') .. "'%1")
  end
  return tag
end

local B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

local function base64(data)
  return ((data:gsub('.', function(c)
    local bits, byte = '', c:byte()
    for i = 8, 1, -1 do bits = bits .. (byte % 2 ^ i - byte % 2 ^ (i - 1) > 0 and '1' or '0') end
    return bits
  end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(bits)
    if #bits < 6 then return '' end
    local n = 0
    for i = 1, 6 do n = n + (bits:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
    return B64:sub(n + 1, n + 1)
  end) .. ({ '', '==', '=' })[#data % 3 + 1])
end

local MIME = { png = 'image/png', jpg = 'image/jpeg', jpeg = 'image/jpeg' }

-- dvisvgm links bitmaps; inlined SVGs need them embedded
local function embed_bitmaps(svg)
  return (svg:gsub("xlink:href='([^'#][^']*)'", function(file)
    local mime = MIME[(file:match('%.(%w+)$') or ''):lower()]
    return mime and ("xlink:href='data:" .. mime .. ';base64,' .. base64(read(file)) .. "'") or nil
  end))
end

local function tex(engine, tmp, name, svg_driver)
  pandoc.pipe(engine, {
    '-interaction=nonstopmode', '-halt-on-error', '-output-directory=' .. tmp,
    (svg_driver and '\\def\\pgfsysdriver{pgfsys-dvisvgm.def}\\PassOptionsToPackage{dvisvgm}{graphicx}' or '')
      .. '\\input{' .. name .. '.tex}',
  }, '')
end

local names = {}
for _, file in ipairs(system.list_directory(here)) do
  local name = file:match('^(.+)%.tex$')
  if name and name ~= 'stil' then names[#names + 1] = name end
end

local target = path.join({ system.get_working_directory(), 'img' })
for _, name in ipairs(names) do
  system.with_temporary_directory('tikz', function(tmp)
    system.with_working_directory(here, function()
      tex('lualatex', tmp, name, false)
      write(path.join({ target, name .. '.pdf' }), read(path.join({ tmp, name .. '.pdf' })))
      tex('dvilualatex', tmp, name, true)
      local svg = path.join({ tmp, name .. '.svg' })
      pandoc.pipe('dvisvgm', { '-v0', '--no-fonts', '--exact-bbox', '--optimize', '-o', svg,
        path.join({ tmp, name .. '.dvi' }) }, '')
      write(path.join({ target, name .. '.svg' }),
        embed_bitmaps((read(svg):gsub('<[^!?][^>]*>', theme_colors))))
    end)
  end)
  print(name)
end
