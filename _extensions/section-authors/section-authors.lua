--- section-authors.lua
--- Lua filter for Quarto books that:
---   1. Reads `author` attributes from ## section headings
---   2. Inserts a Quarto-style author block directly below each ## heading
---
--- Usage in _quarto.yml:
---   filters:
---     - section-authors.lua
---
--- Usage in .qmd:
---   ## My Section {author="Max Mustermann"}
---   ## Collaborative Section {author="Anna Müller, Bob Schmidt"}
  
local List = require 'pandoc.List'
  
--- Build the Quarto-style RawBlock HTML for one or more author names.
-- @param authors  table of author name strings
-- @return pandoc.RawBlock
local function author_html_block(authors)
  local items = {}
  for i, name in ipairs(authors) do
    if i < #authors then
      -- Alle Autoren außer dem letzten
      items[#items + 1] = string.format('      <p style="margin-bottom: .1em; font-size: .9em;">%s</p>', name)
    else
      -- Letzter Autor: größerer margin-bottom für Leerzeile
      items[#items + 1] = string.format('      <p style="margin-bottom: 1em; font-size: .9em;">%s</p>', name)
    end
  end
  -- Use AUTOR:IN for 1 author, AUTOR:INNEN for 2 or more authors
  local heading = (#authors >= 2) and "AUTOR:INNEN" or "AUTOR:IN"
  local html = table.concat({
    '<div>',
    '  <div style="text-transform: uppercase; margin-top: 1em; font-size: .8em; opacity: .8; font-weight: 400;">' .. heading .. '</div>',
    '  <div>',
    table.concat(items, '\n'),
    '  </div>',
    '</div>',
  }, '\n')
  return pandoc.RawBlock('html', html)
end
  
--- Parse a comma-separated author string into a list of trimmed names.
-- @param str  raw author attribute value, e.g. "Anna Müller, Bob Schmidt"
-- @return table of strings
local function parse_authors(str)
  local names = {}
  for name in str:gmatch('[^,]+') do
    name = name:match('^%s*(.-)%s*$')  -- trim whitespace
    if name ~= '' then
      names[#names + 1] = name
    end
  end
  return names
end
  
--- Main filter: process document blocks
return {
  {
    Pandoc = function(doc)
      local blocks = doc.blocks
      local new_blocks = List{}
      for i = 1, #blocks do
        local blk = blocks[i]
        if blk.t == 'Header' and blk.level == 2 then
          local author_attr = blk.attributes and blk.attributes.author
          if author_attr and author_attr ~= '' then
            local authors = parse_authors(author_attr)
            -- Remove author from heading attributes so it doesn't appear elsewhere
            blk.attributes.author = nil
            new_blocks:insert(blk)
            -- Insert author block directly after ## heading
            new_blocks:insert(author_html_block(authors))
          else
            new_blocks:insert(blk)
          end
        else
          new_blocks:insert(blk)
        end
      end
      doc.blocks = new_blocks
      return doc
    end
  }
}