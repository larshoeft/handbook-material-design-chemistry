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

return {
  {
    Image = function(img)
      if not quarto.doc.is_format('html') or not img.src:match('%.svg$') or img.src:match('^%a+:') then
        return nil
      end
      local dir = pandoc.path.directory(quarto.doc.input_file)
      local svg = read(pandoc.path.join({ dir, img.src }))
      if not svg then
        quarto.log.warning('svg-inline: file not found: ' .. img.src)
        return nil
      end
      local alt = img.attributes['fig-alt'] or img.attributes['alt'] or pandoc.utils.stringify(img.caption)
      svg = svg:gsub('<%?xml.-%?>', ''):gsub('<!%-%-.-%-%->', '')
      svg = svg:gsub('<svg ', '<svg role="img" aria-label="' .. escape(alt) .. '" class="svg-inline" style="max-width:100%;height:auto" ', 1)
      return pandoc.RawInline('html', svg)
    end,
  },
}
