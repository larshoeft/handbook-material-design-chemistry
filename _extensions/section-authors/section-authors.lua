--- section-authors.lua
--- Lua filter for Quarto books that:
---   1. Reads `author`, `date` and `license` for ## section headings, from
---      heading attributes or from a metadata entry named after the
---      heading's id
---   2. Inserts a Quarto-style author/date block directly below each ## heading
---   3. Adds a "cite as" reference for sections with a `citation` entry in
---      their metadata (Quarto's citation fields, formatted with `csl`)
---
--- The labels ("Autor:in", "Veröffentlichungsdatum", "Zitat", "Lizenz")
--- are derived from:
---   1. Overrides under Quarto's `language:` key: title-block-author-single,
---      title-block-author-plural, title-block-published,
---      section-title-citation, section-title-reuse
---   2. doc.meta.lang (e.g. lang: de -> "Autor:in" / "Autor:innen")
---   3. Fallback: English
---
--- Usage in _quarto.yml:
---   filters:
---     - at: pre-quarto
---       path: section-authors
---
--- Usage in .qmd (heading attributes take precedence over metadata):
---   ## My Section {author="Max Mustermann" date="2026-10-02"}
---   ## Collaborative Section {author="Anna Müller, Bob Schmidt"}
---
---   ---
---   sec-my-section:
---     author: "Max Mustermann"       # or a list of names
---     date: 2026-10-02
---     license: "CC BY-NC"            # CC abbreviations link to the deed
---     citation:                      # optional; `true` for defaults only
---       type: chapter                # title/author/issued default to the
---       container-title: "…"         # heading, author and date above
---   ---
---   ## My Section {#sec-my-section}
---
--- Front matter of {{< include >}}d files is merged into the chapter key
--- by key (a later file replaces a key, it does not merge into it).
--- Hence one top-level key per section: it neither overrides the
--- chapter's own `author` / `date` nor another section's entry.

--- Extension name, used for log messages and the HTML dependency
local EXTENSION_NAME = 'section-authors'

--- Extension version (keep in sync with _extension.yml)
local EXTENSION_VERSION = '0.2.0'

--- Load required modules
local List  = require 'pandoc.List'
local utils = require 'pandoc.utils'

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

--- Keys allowed in a section's metadata entry
---@type table<string, boolean>
local SECTION_KEYS = { author = true, date = true, license = true,
                       citation = true }

-- Language lookup table for author labels
-- Covers Quarto's supported languages; extend as needed.
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

-- Quarto's `title-block-published` per language; extend as needed.
local PUBLISHED = {
  de = 'Veröffentlichungsdatum',
  en = 'Published',
}

-- Long date formats matching Quarto's title block; extend as needed.
local MONTHS = {
  de = { 'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni', 'Juli',
         'August', 'September', 'Oktober', 'November', 'Dezember' },
  en = { 'January', 'February', 'March', 'April', 'May', 'June', 'July',
         'August', 'September', 'October', 'November', 'December' },
}

local DATE_FORMAT = {
  de = function(y, m, d) return string.format('%d. %s %d', d, m, y) end,
  en = function(y, m, d) return string.format('%s %d, %d', m, d, y) end,
}

-- ---------------------------------------------------------------------------
-- Private helper functions
-- ---------------------------------------------------------------------------

---Report a problem via Quarto's logger (plain stderr outside Quarto).
---@param message string
local function warn(message)
  message = '[' .. EXTENSION_NAME .. '] ' .. message
  if quarto and quarto.log then
    quarto.log.warning(message)
  else
    io.stderr:write(message .. '\n')
  end
end

---Base language code of the document (`lang: de-DE` -> "de").
---@param meta Meta document metadata
---@return string
local function lang_base(meta)
  local lang = meta.lang and utils.stringify(meta.lang) or 'en'
  return lang:match('^(%a+)') or 'en'
end

---Format an ISO date (YYYY-MM-DD) in the long form of the document
---language; other strings are returned unchanged.
---@param date string date as written in the source
---@param base string base language code
---@return string
local function format_date(date, base)
  local y, m, d = date:match('^(%d%d%d%d)%-(%d%d)%-(%d%d)$')
  if not y then return date end
  if not DATE_FORMAT[base] then base = 'en' end
  local month = MONTHS[base][tonumber(m)]
  if not month then return date end
  return DATE_FORMAT[base](tonumber(y), month, tonumber(d))
end

-- Quarto's `section-title-citation` per language; extend as needed.
local CITATION = {
  de = 'Zitat',
  en = 'Citation',
}

-- License label per language; extend as needed.
-- (Quarto's own `section-title-reuse` reads "Wiederverwendung" / "Reuse".)
local LICENSE = {
  de = 'Lizenz',
  en = 'License',
}

---Label override, as documented by Quarto under `language:`
---(top-level keys are accepted as well).
---@param meta Meta document metadata
---@param key string Quarto translation key
---@return string|nil
local function override(meta, key)
  local language = meta.language
  local value = (utils.type(language) == 'table' and language[key])
                or meta[key]
  return value and utils.stringify(value)
end

---Resolve author, date, citation and license labels.
---Priority: overrides (`language:` keys) > lang lookup > English fallback
---@param meta Meta document metadata
---@param base string base language code
---@return table<string, string>
local function get_labels(meta, base)
  return {
    single    = override(meta, 'title-block-author-single')
                or AUTHOR_SINGLE[base] or AUTHOR_SINGLE['en'],
    plural    = override(meta, 'title-block-author-plural')
                or AUTHOR_PLURAL[base] or AUTHOR_PLURAL['en'],
    published = override(meta, 'title-block-published')
                or PUBLISHED[base] or PUBLISHED['en'],
    citation  = override(meta, 'section-title-citation')
                or CITATION[base] or CITATION['en'],
    license   = override(meta, 'section-title-reuse')
                or LICENSE[base] or LICENSE['en'],
  }
end

---License inlines from a metadata value or attribute. As in Quarto,
---Creative Commons abbreviations ("CC BY-NC", "CC BY-SA 3.0", "CC0")
---link to the license deed (version 4.0 unless given); a map may give
---`text` and `url`; anything else is shown as text.
---@param value string|MetaValue
---@return Inlines|nil
local function license_inlines(value)
  local text, url
  if utils.type(value) == 'table' then
    text = value.text and utils.stringify(value.text)
    url  = value.url and utils.stringify(value.url)
  else
    text = utils.stringify(value)
  end
  if not text or text == '' then
    if not url then return nil end
    text = url
  end
  if not url then
    local upper = text:upper()
    local code, version = upper:match('^CC[%s%-]+(BY[%-A-Z]*)%s*(%d?%.?%d?)$')
    if code then
      version = (version ~= '') and version or '4.0'
      text = 'CC ' .. code .. ' ' .. version
      url  = 'https://creativecommons.org/licenses/' .. code:lower()
             .. '/' .. version .. '/'
    elseif upper:match('^CC[%s%-]*0%s*1?%.?0?$') then
      text = 'CC0 1.0'
      url  = 'https://creativecommons.org/publicdomain/zero/1.0/'
    end
  end
  if url then
    return pandoc.Inlines {
      pandoc.Link(text, url, '', pandoc.Attr('', {}, { rel = 'license' }))
    }
  end
  return pandoc.Inlines { pandoc.Str(text) }
end

---CSL name from a Quarto-style author ("Max Mustermann" or a map with
---`name`, or already `family`/`given`/`literal`).
---@param author string|MetaValue
---@return table CSL name
local function csl_name(author)
  if utils.type(author) == 'table'
      and (author.family or author.literal) then
    return author
  end
  local name = utils.stringify(utils.type(author) == 'table'
                               and author.name or author)
  local given, family = name:match('^(.-)%s+(%S+)$')
  if not family then return { literal = name } end
  return { given = given, family = family }
end

---CSL names from one author or a list of authors (see csl_name).
---@param value string|MetaValue|string[]|nil
---@return table[]|nil CSL names, nil if there are none
local function csl_names(value)
  if value == nil then return nil end
  local kind = utils.type(value)
  local is_list = kind == 'List' or (kind == 'table' and value[1] ~= nil)
  if not is_list then value = { value } end  -- one name or name map
  local names = List {}
  for _, a in ipairs(value) do names:insert(csl_name(a)) end
  return #names > 0 and names or nil
end

---Format the section's `citation` metadata with citeproc (using the
---document's `csl` and `lang`). Missing title, author and issued are
---taken from the heading, the section authors and the section date;
---for `type: chapter`, missing container-title and editor from the
---book title and the chapter's (or book's) authors.
---@param citation MetaValue|boolean `citation` entry (`true` = defaults)
---@param header Header the section heading
---@param authors string[] section authors
---@param date string|nil section date as written in the source
---@param meta Meta document metadata
---@return Blocks|nil formatted reference, nil on failure
local function format_citation(citation, header, authors, date, meta)
  local item = {}
  if utils.type(citation) == 'table' then  -- `citation: true` = defaults only
    for k, v in pairs(citation) do item[k] = v end
  end
  item.id    = 'section-citation'
  item.type  = item.type and utils.stringify(item.type) or 'chapter'
  item.title = item.title or utils.stringify(header.content)
  item.issued = item.issued or date

  item.author = csl_names(item.author or authors)

  -- A chapter belongs to the book: default to the book title and the
  -- chapter's authors (or the book's) as editors.
  if item.type == 'chapter' then
    local book = utils.type(meta.book) == 'table' and meta.book or {}
    item['container-title'] = item['container-title'] or book.title
    item.editor = csl_names(item.editor or meta.author or book.author)
  end

  local cite_meta = {
    references = { item },
    nocite     = pandoc.Inlines {
      pandoc.Cite({}, { pandoc.Citation('section-citation', 'NormalCitation') })
    },
    csl        = meta.csl,
    lang       = meta.lang,
  }
  local ok, result = pcall(utils.citeproc,
    pandoc.Pandoc({ pandoc.Div({}, pandoc.Attr('refs')) }, cite_meta))
  if not ok then
    warn('citation for #' .. header.identifier .. ' failed: '
         .. tostring(result))
    return nil
  end

  -- Keep only the entry's content: ids and classes like `ref-…` and
  -- `csl-bib-body` would be picked up by section-bibliographies.
  local entry
  result.blocks:walk {
    Div = function(d)
      if d.classes:includes('csl-entry') then entry = d.content end
    end,
  }
  return entry
end

---One labelled field (label + contents), like Quarto's title block.
---@param label string
---@param contents Block
---@return Div
local function field(label, contents)
  return pandoc.Div({
    pandoc.Div(pandoc.Plain(pandoc.Str(label)),
      pandoc.Attr('', { 'section-authors-label' })),
    contents,
  })
end

---Build the author/date block for a section.
---Uses plain Pandoc elements (escaped by the writer, usable in every
---output format); HTML styling comes from section-authors.css.
---@param authors string[] author names (may be empty)
---@param date string|nil date as written in the source
---@param labels table labels from get_labels
---@param reference Blocks|nil formatted citation
---@param license Inlines|nil license text or link
---@return Div
local function author_block(authors, date, labels, reference, license)
  local fields = List {}
  if #authors > 0 then
    local names = List {}
    for _, name in ipairs(authors) do
      names:insert(pandoc.Div(pandoc.Plain(pandoc.Str(name)),
        pandoc.Attr('', { 'section-authors-name' })))
    end
    local label = (#authors >= 2) and labels.plural or labels.single
    fields:insert(field(label,
      pandoc.Div(names, pandoc.Attr('', { 'section-authors-names' }))))
  end
  if date then
    fields:insert(field(labels.published,
      pandoc.Div(pandoc.Plain(pandoc.Str(date)),
        pandoc.Attr('', { 'section-authors-date' }))))
  end
  if license then
    fields:insert(field(labels.license,
      pandoc.Div(pandoc.Plain(license),
        pandoc.Attr('', { 'section-authors-license' }))))
  end
  if reference then
    local cite = field(labels.citation,
      pandoc.Div(reference, pandoc.Attr('', { 'section-authors-citation' })))
    cite.classes:insert('section-authors-wide')
    fields:insert(cite)
  end
  return pandoc.Div(fields, pandoc.Attr('', { 'section-authors' }))
end

---Register the stylesheet for HTML output.
local function add_css()
  if quarto and quarto.doc and quarto.doc.is_format('html') then
    quarto.doc.add_html_dependency({
      name = EXTENSION_NAME,
      version = EXTENSION_VERSION,
      stylesheets = { 'section-authors.css' },
    })
  end
end

---Parse a comma-separated author string into a list of trimmed names.
---@param str string
---@return string[]
local function parse_authors(str)
  local names = {}
  for name in str:gmatch('[^,]+') do
    name = name:match('^%s*(.-)%s*$')
    if name ~= '' then names[#names + 1] = name end
  end
  return names
end

---Author names from a metadata value: a list of names (or of maps with
---`name`, as in Quarto's `author`) or a comma-separated string.
---@param value MetaValue|nil
---@return string[]
local function meta_authors(value)
  if value == nil then return {} end
  if utils.type(value) == 'List' then
    local names = {}
    for _, item in ipairs(value) do
      local name = utils.type(item) == 'table' and item.name or item
      if name then names[#names + 1] = utils.stringify(name) end
    end
    return names
  end
  return parse_authors(utils.stringify(value))
end

---Metadata entry for a section id: a map under that top-level key, or
---(deprecated) under `section-meta`.
---@param meta Meta document metadata
---@param id string section id
---@return table|nil
local function section_entry(meta, id)
  if id == '' then return nil end
  local entry = meta[id]
  if utils.type(entry) ~= 'table'
      and utils.type(meta['section-meta']) == 'table' then
    entry = meta['section-meta'][id]
  end
  return utils.type(entry) == 'table' and entry or nil
end

---Warn about keys a section entry does not support (likely typos).
---@param id string section id
---@param entry table section metadata entry
local function validate_entry(id, entry)
  for key in pairs(entry) do
    if not SECTION_KEYS[key] then
      warn('unknown key "' .. key .. '" in metadata "' .. id
           .. '"; supported: author, date, license, citation')
    end
  end
end

---Author names, date, citation metadata and license for a ## heading.
---Heading attributes take precedence over the metadata entry for the
---heading's id; the citation comes from the metadata only.
---@param blk Header
---@param meta Meta document metadata
---@return string[] authors
---@return string|nil date
---@return MetaValue|nil citation
---@return Inlines|nil license
local function section_info(blk, meta)
  local entry   = section_entry(meta, blk.identifier) or {}
  validate_entry(blk.identifier, entry)
  local attrs   = blk.attributes
  local authors = (attrs.author and attrs.author ~= '')
                  and parse_authors(attrs.author)
                  or meta_authors(entry.author)
  local date    = (attrs.date and attrs.date ~= '') and attrs.date
                  or (entry.date and utils.stringify(entry.date))
  if date and not date:match('^%d%d%d%d%-%d%d%-%d%d$') then
    warn('date "' .. date .. '" of #' .. blk.identifier
         .. ' is not YYYY-MM-DD; shown as written')
  end
  local license = (attrs.license and attrs.license ~= '') and attrs.license
                  or entry.license
  attrs.author  = nil
  attrs.date    = nil
  attrs.license = nil
  return authors, date, entry.citation, license and license_inlines(license)
end

-- ---------------------------------------------------------------------------
-- Extension registration
-- ---------------------------------------------------------------------------

return {
  {
    Pandoc = function(doc)
      add_css()
      if doc.meta['section-meta'] then
        warn('"section-meta" is deprecated: put each entry at top level, '
             .. 'e.g. "sec-my-section:" (entries of included files '
             .. 'otherwise replace each other)')
      end
      local base         = lang_base(doc.meta)
      local labels       = get_labels(doc.meta, base)
      local blocks       = doc.blocks
      local new_blocks   = List {}
      local seen         = {}

      for i = 1, #blocks do
        local blk = blocks[i]
        if blk.t == 'Header' and blk.level == 2 then
          seen[blk.identifier] = true
          local authors, date, citation, license =
            section_info(blk, doc.meta)
          local reference = citation
            and format_citation(citation, blk, authors, date, doc.meta)
          new_blocks:insert(blk)
          if #authors > 0 or date or reference or license then
            new_blocks:insert(author_block(authors,
              date and format_date(date, base), labels, reference, license))
          end
        else
          new_blocks:insert(blk)
        end
      end

      -- `sec-` entries without a matching ## heading are most likely typos.
      for key in pairs(doc.meta) do
        if key:match('^sec%-') and section_entry(doc.meta, key)
            and not seen[key] then
          warn('metadata "' .. key .. '" matches no ## heading')
        end
      end

      doc.blocks = new_blocks
      return doc
    end
  }
}
