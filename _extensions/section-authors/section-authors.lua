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
---     - at: pre-quarto
---       path: section-authors
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

--- Build the author block for one or more author names.
--- Uses plain Pandoc elements (escaped by the writer, usable in every
--- output format); HTML styling comes from section-authors.css.
---@param authors string[] author names
---@param label_single string label for one author
---@param label_plural string label for several authors
---@return Div
local function author_block(authors, label_single, label_plural)
  local heading = (#authors >= 2) and label_plural or label_single
  local names = List {}
  for _, name in ipairs(authors) do
    names:insert(pandoc.Div(pandoc.Plain(pandoc.Str(name)),
      pandoc.Attr('', { 'section-authors-name' })))
  end
  return pandoc.Div({
    pandoc.Div(pandoc.Plain(pandoc.Str(heading)),
      pandoc.Attr('', { 'section-authors-label' })),
    pandoc.Div(names, pandoc.Attr('', { 'section-authors-names' })),
  }, pandoc.Attr('', { 'section-authors' }))
end

--- Register the stylesheet for HTML output.
local function add_css()
  if quarto and quarto.doc and quarto.doc.is_format('html') then
    quarto.doc.add_html_dependency({
      name = 'section-authors',
      version = '0.1.0',
      stylesheets = { 'section-authors.css' },
    })
  end
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
      add_css()
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
            new_blocks:insert(author_block(authors, label_single, label_plural))
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
