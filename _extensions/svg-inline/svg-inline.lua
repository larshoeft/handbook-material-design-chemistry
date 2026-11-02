--- Embeds local SVG images in HTML so that theme CSS variables (--fig-*) apply.

local function read(path)
  local file = io.open(path, 'r')
  if not file then return nil end
  local content = file:read('a')
  file:close()
  return content
end

local function escape(text)
  return (text:gsub('&', '&amp;'):gsub('"', '&quot;'):gsub('<', '&lt;'))
end

-- Inlined SVGs share one document, so ids must be unique per file
local function prefix_ids(svg, prefix)
  prefix = prefix:gsub('%%', '%%%%')
  svg = svg:gsub('(%sid=["\'])', '%1' .. prefix .. '-')
  svg = svg:gsub('(url%(#)', '%1' .. prefix .. '-')
  svg = svg:gsub('(href=["\']#)', '%1' .. prefix .. '-')
  return svg
end

-- `figure-variant: ipn` prefers name.ipn.svg over name.svg (fonts per theme)
local variant

return {
  {
    Meta = function(meta)
      variant = meta['figure-variant'] and pandoc.utils.stringify(meta['figure-variant'])
    end,
  },
  {
    Image = function(img)
      if not quarto.doc.is_format('html') or not img.src:match('%.svg$') or img.src:match('^%a+:') then
        return nil
      end
      local dir = pandoc.path.directory(quarto.doc.input_file)
      local file = pandoc.path.join({ dir, img.src })
      local svg = variant and read(file:gsub('%.svg$', '.' .. variant .. '.svg')) or read(file)
      if not svg then
        quarto.log.warning('svg-inline: file not found: ' .. img.src)
        return nil
      end
      local name = pandoc.path.split_extension(pandoc.path.filename(img.src))
      svg = prefix_ids(svg:gsub('<%?xml.-%?>', ''):gsub('<!%-%-.-%-%->', ''), name)

      local alt = img.attributes['fig-alt'] or img.attributes['alt'] or pandoc.utils.stringify(img.caption)
      local style = img.attributes.width and ('width:' .. img.attributes.width .. ';height:auto')
                    or 'max-width:100%;height:auto'
      local classes = table.concat({ 'svg-inline', table.unpack(img.classes) }, ' ')
      local attrs = 'role="img" aria-label="' .. escape(alt) .. '" class="' .. escape(classes)
                    .. '" style="' .. escape(style) .. '"'
      if img.identifier ~= '' then attrs = attrs .. ' id="' .. escape(img.identifier) .. '"' end

      local found
      svg, found = svg:gsub('<svg([%s>])', function(after) return '<svg ' .. attrs .. after end, 1)
      if found == 0 then
        quarto.log.warning('svg-inline: no <svg> element in ' .. img.src)
        return nil
      end
      return pandoc.RawInline('html', svg)
    end,
  },
}
