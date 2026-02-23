--- section-authors.lua
--- Lua filter for Quarto books that:
---   1. Reads `author` attributes from ## section headings
---   2. Inserts a Quarto-style author block directly below each ## heading
---
--- The "Autor:in" / "Autor:innen" label is derived from:
---   1. Quarto language overrides: title-block-author-single / title-block-author-plural
---   2. doc.meta.lang (e.g. lang: de -> "Autor:in" / "Autor:innen")
---   3. Fallback: "Author" / "Authors"
---
--- Usage in _quarto.yml:
---   filters:
---     - section-authors.lua
---
--- Usage in .qmd:
---   ## My Section {author="Max Mustermann"}
---   ## Collaborative Section {author="Anna Müller, Bob Schmidt"}

local List          = require 'pandoc.List'
local utils         = require 'pandoc.utils'

-- ---------------------------------------------------------------------------
-- Language lookup table for author labels
-- Covers Quarto's supported languages; extend as needed.
-- ---------------------------------------------------------------------------
local AUTHOR_SINGLE = {
  af = 'Outeur',
  ar = 'المؤلف',
  bg = 'Автор',
  ca = 'Autor',
  cs = 'Autor',
  da = 'Forfatter',
  de = 'Autor:in',
  el = 'Συγγραφέας',
  en = 'Author',
  eo = 'Aŭtoro',
  es = 'Autor',
  et = 'Autor',
  eu = 'Egilea',
  fi = 'Tekijä',
  fr = 'Auteur',
  he = 'מחבר',
  hr = 'Autor',
  hu = 'Szerző',
  id = 'Penulis',
  it = 'Autore',
  ja = '著者',
  ko = '저자',
  lt = 'Autorius',
  lv = 'Autors',
  nb = 'Forfatter',
  nl = 'Auteur',
  nn = 'Forfattar',
  pl = 'Autor',
  pt = 'Autor',
  ro = 'Autor',
  ru = 'Автор',
  sk = 'Autor',
  sl = 'Avtor',
  sr = 'Аутор',
  sv = 'Författare',
  th = 'ผู้แต่ง',
  tr = 'Yazar',
  uk = 'Автор',
  vi = 'Tác giả',
  zh = '作者',
}

local AUTHOR_PLURAL = {
  af = 'Outeurs',
  ar = 'المؤلفون',
  bg = 'Автори',
  ca = 'Autors',
  cs = 'Autoři',
  da = 'Forfattere',
  de = 'Autor:innen',
  el = 'Συγγραφείς',
  en = 'Authors',
  eo = 'Aŭtoroj',
  es = 'Autores',
  et = 'Autorid',
  eu = 'Egileak',
  fi = 'Tekijät',
  fr = 'Auteurs',
  he = 'מחברים',
  hr = 'Autori',
  hu = 'Szerzők',
  id = 'Para Penulis',
  it = 'Autori',
  ja = '著者',
  ko = '저자',
  lt = 'Autoriai',
  lv = 'Autori',
  nb = 'Forfattere',
  nl = 'Auteurs',
  nn = 'Forfattarar',
  pl = 'Autorzy',
  pt = 'Autores',
  ro = 'Autori',
  ru = 'Авторы',
  sk = 'Autori',
  sl = 'Avtorji',
  sr = 'Аутори',
  sv = 'Författare',
  th = 'ผู้แต่ง',
  tr = 'Yazarlar',
  uk = 'Автори',
  vi = 'Các tác giả',
  zh = '作者',
}

--- Resolve author label from metadata.
-- Priority: Quarto language overrides > lang lookup > English fallback
local function get_author_labels(meta)
  local single = meta['title-block-author-single']
  local plural = meta['title-block-author-plural']
  if single then single = utils.stringify(single) end
  if plural then plural = utils.stringify(plural) end

  if not single or not plural then
    local lang = meta.lang and utils.stringify(meta.lang) or 'en'
    local base = lang:match('^(%a+)') or 'en'
    single     = single or AUTHOR_SINGLE[base] or AUTHOR_SINGLE['en']
    plural     = plural or AUTHOR_PLURAL[base] or AUTHOR_PLURAL['en']
  end
  return single, plural
end

--- Build the Quarto-style RawBlock HTML for one or more author names.
local function author_html_block(authors, label_single, label_plural)
  local items = {}
  for i, name in ipairs(authors) do
    local margin = (i < #authors) and '.1em' or '1em'
    items[#items + 1] = string.format(
      '      <p style="margin-bottom: %s; font-size: .9em;">%s</p>', margin, name)
  end
  local heading = (#authors >= 2) and label_plural or label_single
  local html = table.concat({
    '<div>',
    '  <div style="text-transform: uppercase; margin-top: 1em; font-size: .8em; opacity: .8; font-weight: 400;">' ..
    heading .. '</div>',
    '  <div>',
    table.concat(items, ''),
    '  </div>',
    '</div>',
  }, '\n')
  return pandoc.RawBlock('html', html)
end

--- Parse a comma-separated author string into a list of trimmed names.
local function parse_authors(str)
  local names = {}
  for name in str:gmatch('[^,]+') do
    name = name:match('^%s*(.-)%s*$')
    if name ~= '' then names[#names + 1] = name end
  end
  return names
end

--- Main filter
return {
  {
    Pandoc = function(doc)
      local label_single, label_plural = get_author_labels(doc.meta)
      local blocks                     = doc.blocks
      local new_blocks                 = List {}

      for i = 1, #blocks do
        local blk = blocks[i]
        if blk.t == 'Header' and blk.level == 2 then
          local author_attr = blk.attributes and blk.attributes.author
          if author_attr and author_attr ~= '' then
            local authors = parse_authors(author_attr)
            blk.attributes.author = nil
            new_blocks:insert(blk)
            new_blocks:insert(author_html_block(authors, label_single, label_plural))
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
