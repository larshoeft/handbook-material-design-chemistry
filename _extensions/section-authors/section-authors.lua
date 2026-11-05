--- section-authors.lua
--- Resolves the people of a Quarto book chapter (`author` with ids from
--- `book.author` and `contributors`) for the title block and adds a
--- citation and the license there. `::: section-authors-all` lists all
--- people and cites the whole book. Usage and options: see README.md.

--- Extension name, used for log messages and the HTML dependency
local EXTENSION_NAME = 'section-authors'

--- Extension version (keep in sync with _extension.yml)
local EXTENSION_VERSION = '0.9.0'

--- Load required modules
local List  = require 'pandoc.List'
local utils = require 'pandoc.utils'

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

--- ORCID iD (four blocks of four digits, last check digit may be X)
local ORCID_PATTERN = '^%d%d%d%d%-%d%d%d%d%-%d%d%d%d%-%d%d%d[%dX]$'

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

---License inlines from a metadata value. As in Quarto, Creative Commons
---abbreviations ("CC BY-NC", "CC BY-SA 3.0", "CC0") link to the license
---deed (version 4.0 unless given); a map may give `text` and `url`;
---anything else is shown as text.
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

---Book title for citations: `book.title`, with `book.subtitle` after a
---colon as APA joins them.
---@param book table book metadata
---@return string|nil
local function book_title(book)
  if not book.title then return nil end
  local title = utils.stringify(book.title)
  if book.subtitle then
    title = title .. ': ' .. utils.stringify(book.subtitle)
  end
  return title
end

---Year of a date as written or formatted (the first four digits).
---@param date MetaValue|nil
---@return string
local function year_of(date)
  return date and utils.stringify(date):match('%d%d%d%d') or os.date('%Y')
end

---Web address of the current page from `book.site-url` (or `site-url`).
---@param meta Meta document metadata
---@return string|nil
local function page_url(meta)
  local book = utils.type(meta.book) == 'table' and meta.book or {}
  local base = book['site-url'] or meta['site-url']
  if not base or not (quarto.project and quarto.project.directory) then return nil end
  base = utils.stringify(base):gsub('/*$', '/')
  local page = pandoc.path.make_relative(quarto.doc.input_file, quarto.project.directory)
  page = page:gsub('\\', '/'):gsub('%.qmd$', '.html')
  if page == 'index.html' then page = '' end
  return base .. page
end

---Format one CSL item with citeproc (using the document's `csl` and
---`lang`) and keep only the entry's content: ids and classes like `ref-…`
---and `csl-bib-body` would be picked up by section-bibliographies.
---@param item table CSL item
---@param meta Meta document metadata
---@return Blocks|nil formatted reference, nil on failure
local function run_citeproc(item, meta)
  item.id = 'section-citation'
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
    warn('citation of ' .. quarto.doc.input_file .. ' failed: ' .. tostring(result))
    return nil
  end
  local entry
  result.blocks:walk {
    Div = function(d)
      if d.classes:includes('csl-entry') then entry = d.content end
    end,
  }
  return entry
end

---Chapter title without the number Quarto puts in front of it.
---@param meta Meta document metadata
---@return string|nil
local function chapter_title(meta)
  local title = meta.title
  if not title then return nil end
  if utils.type(title) == 'Inlines' then
    title:walk { Span = function(span)
      if span.classes:includes('chapter-title') then title = span.content end
    end }
  end
  return utils.stringify(title)
end

---Citation of a chapter: its title, authors and year, in the book
---(editors from `book.author`) with the page address.
---@param authors table[] author records
---@param meta Meta document metadata
---@return Blocks|nil formatted reference, nil on failure
local function format_chapter_citation(authors, meta)
  local book = utils.type(meta.book) == 'table' and meta.book or {}
  return run_citeproc({
    type              = 'chapter',
    title             = chapter_title(meta),
    author            = csl_names(authors),
    issued            = year_of(meta.date),
    ['container-title'] = book_title(book),
    editor            = csl_names(book.author),
    URL               = page_url(meta),
  }, meta)
end

---Citation of the whole book (editors from `book.author`).
---@param meta Meta document metadata
---@return Blocks|nil formatted reference, nil on failure
local function format_book_citation(meta)
  local book = utils.type(meta.book) == 'table' and meta.book or {}
  return run_citeproc({
    type   = 'book',
    title  = book_title(book),
    editor = csl_names(book.author),
    issued = year_of(book.date or meta.date),
    URL    = page_url(meta),
  }, meta)
end

---Whether the output is HTML.
---@return boolean
local function is_html()
  return quarto and quarto.doc and quarto.doc.is_format('html') or false
end

---Contact link after an author name: in HTML an icon (styled by
---section-authors.css) with the label for screen readers, elsewhere the
---text. Without a URL a span with the same icon (HTML) or the text alone.
---@param text string visible text outside HTML
---@param url string|nil link target
---@param kind string "email", "orcid" or "affiliation"
---@param label string accessible label / tooltip
---@return Inline
local function contact_link(text, url, kind, label)
  local class = 'section-authors-' .. kind
  if is_html() then
    local hidden = pandoc.Span(pandoc.Str(label),
      pandoc.Attr('', { 'visually-hidden' }))
    if not url then
      return pandoc.Span(hidden, pandoc.Attr('', { class },
        { title = label }))
    end
    return pandoc.Link(hidden, url, label, pandoc.Attr('', { class }))
  end
  if not url then return pandoc.Str(text) end
  return pandoc.Link(pandoc.Str(text), url, label, pandoc.Attr('', { class }))
end

---Inlines for one author: name, then icons from the person outward
---(ORCID = who, affiliation = where, e-mail = contact).
---@param author table author record (see meta_authors)
---@return Inlines
local function author_inlines(author)
  local inlines = pandoc.Inlines { pandoc.Str(author.name) }
  if author.orcid then
    inlines:insert(pandoc.Space())
    inlines:insert(contact_link('ORCID ' .. author.orcid,
      'https://orcid.org/' .. author.orcid, 'orcid',
      'ORCID ' .. author.orcid))
  end
  for _, aff in ipairs(author.affiliations or {}) do
    inlines:insert(pandoc.Space())
    inlines:insert(contact_link(aff.name, aff.url, 'affiliation', aff.name))
  end
  if author.email then
    inlines:insert(pandoc.Space())
    inlines:insert(contact_link(author.email, 'mailto:' .. author.email,
      'email', author.email))
  end
  return inlines
end

---Register the stylesheet for HTML output.
local function add_css()
  if is_html() then
    quarto.doc.add_html_dependency({
      name = EXTENSION_NAME,
      version = EXTENSION_VERSION,
      stylesheets = { 'section-authors.css' },
    })
  end
end

local known_authors = {}
local known_affiliations = {}

local function index_by_id(value, index)
  index = index or {}
  if utils.type(value) ~= 'List' then return index end
  for _, item in ipairs(value) do
    if utils.type(item) == 'table' and item.id then
      index[utils.stringify(item.id)] = item
    end
  end
  return index
end

---Affiliations from Quarto's `affiliation(s)`: a name, a map with
---`name` and `url` or `ref` (id in `affiliations`), or a list of these.
---URLs without a scheme ("www.example.org") get "https://".
---@param value MetaValue|nil
---@return table[] records with name and url
local function affiliation_list(value)
  if value == nil then return {} end
  local kind = utils.type(value)
  if kind ~= 'List' then value = { value } end  -- one name or map
  local result = {}
  for _, item in ipairs(value) do
    local name, url
    if utils.type(item) == 'table' then
      if item.ref then
        local ref = utils.stringify(item.ref)
        if not known_affiliations[ref] then
          warn('unknown affiliation ref "' .. ref .. '"')
        end
        item = known_affiliations[ref] or {}
      end
      name = item.name and utils.stringify(item.name)
      url  = item.url and utils.stringify(item.url)
      if url and not url:match('^%a[%w+.-]*:') then
        url = 'https://' .. url  -- "www.example.org" -> absolute link
      end
    else
      name = utils.stringify(item)
    end
    if name and name ~= '' then
      result[#result + 1] = { name = name, url = url }
    end
  end
  return result
end

---Author record from a map in Quarto's author schema: `name`, plus
---optional `email`, `orcid` (ID or https://orcid.org/… URL) and
---`affiliation(s)` (names or maps with `name` and `url`).
---Other keys (`id`, …) are accepted and not shown.
---@param item table author map
---@return table|nil record with name, email, orcid, affiliations
local function author_record(item)
  if not item.name then
    warn('author without "name" in ' .. quarto.doc.input_file)
    return nil
  end
  local author = { name = utils.stringify(item.name) }
  if item.email then
    author.email = utils.stringify(item.email)
  end
  if item.orcid then
    local orcid = utils.stringify(item.orcid)
                  :gsub('^https?://orcid%.org/', ''):upper()
    if not orcid:match(ORCID_PATTERN) then
      warn('ORCID "' .. orcid .. '" of ' .. author.name
           .. ' is not 0000-0000-0000-0000; ignored')
    else
      author.orcid = orcid
    end
  end
  author.affiliations = affiliation_list(item.affiliation
                                         or item.affiliations)
  return author
end

---Author record for an id or a name in `book.author` or `contributors`,
---or for another full name; a single unknown word is likely a mistyped id.
---@param name string
---@return table
local function author_from_string(name)
  local item = known_authors[name]
  if item then return author_record(item) end
  for _, person in pairs(known_authors) do
    if person.name and utils.stringify(person.name) == name then
      return author_record(person)
    end
  end
  if not name:match('%s') then
    warn('author "' .. name .. '" in ' .. quarto.doc.input_file
         .. ' is no known id and no full name; check "book.author" and '
         .. '"contributors"')
  end
  return { name = name }
end

---Author records from `author`: a name or id, a Quarto author map, a
---`ref` map, a list of these, or a comma-separated string.
---@param value MetaValue|nil
---@return table[]
local function meta_authors(value)
  if value == nil then return {} end
  local kind = utils.type(value)
  local items = {}
  if kind == 'List' then
    items = value
  elseif kind == 'table' then
    items = { value }  -- one author map
  else
    for name in utils.stringify(value):gmatch('[^,]+') do
      items[#items + 1] = name:match('^%s*(.-)%s*$')
    end
  end
  local authors = {}
  for _, item in ipairs(items) do
    local author
    if utils.type(item) == 'table' and item.ref then
      local ref = utils.stringify(item.ref)
      author = known_authors[ref] and author_record(known_authors[ref])
      if not author then
        warn('unknown author ref "' .. ref .. '" in ' .. quarto.doc.input_file)
      end
    elseif utils.type(item) == 'table' then
      author = author_record(item)
    else
      local name = utils.stringify(item)
      if name:match('@') or name:match(ORCID_PATTERN) then
        warn('author "' .. name .. '" looks like an e-mail or ORCID; '
             .. 'use "name:", "email:" and "orcid:"')
      end
      if name ~= '' then author = author_from_string(name) end
    end
    if author then authors[#authors + 1] = author end
  end
  return authors
end

---Authors in the form of Quarto's normalized `by-author`, which the
---title block partial (title-metadata.html) shows. Quarto reads `author`
---before filters run, so ids would leave it without names.
---@param authors table[] author records
---@return table
local function by_author(authors)
  local list = List {}
  for _, a in ipairs(authors) do
    list:insert({
      name = { literal = a.name },
      orcid = a.orcid,
      email = a.email,
      affiliations = a.affiliations and #a.affiliations > 0 and a.affiliations or nil,
    })
  end
  return list
end

---All people in `book.author` and `contributors`, sorted by family name,
---as one inline list with icons. The label ignores the title-block
---overrides, which name the editors.
---@param meta Meta document metadata
---@param base string base language code
---@return MetaBlocks names
---@return string label
local function all_authors(meta, base)
  local authors = List {}
  local book = utils.type(meta.book) == 'table' and meta.book or {}
  for _, value in ipairs({ book.author, meta.contributors }) do
    if utils.type(value) == 'List' then
      for _, item in ipairs(value) do
        local author = utils.type(item) == 'table' and author_record(item)
        if author then authors:insert(author) end
      end
    end
  end
  local function family(a) return (a.name:match('(%S+)$') or a.name):lower() end
  table.sort(authors, function(a, b) return family(a) < family(b) end)
  local names = pandoc.Inlines {}
  for i, author in ipairs(authors) do
    if i > 1 then names:extend { pandoc.Str(','), pandoc.Space() } end
    names:insert(pandoc.Span(author_inlines(author),
      pandoc.Attr('', { 'section-authors-name' })))
  end
  local labels = (#authors >= 2) and AUTHOR_PLURAL or AUTHOR_SINGLE
  return pandoc.MetaBlocks { pandoc.Para(names) }, labels[base] or labels['en']
end

-- ---------------------------------------------------------------------------
-- Extension registration
-- ---------------------------------------------------------------------------

return {
  {
    Pandoc = function(doc)
      add_css()
      local meta = doc.meta
      local book = utils.type(meta.book) == 'table' and meta.book or {}
      known_authors = index_by_id(book.author)
      index_by_id(meta.contributors, known_authors)
      known_affiliations = index_by_id(meta.affiliations)
      local options = meta.extensions and meta.extensions[EXTENSION_NAME] or {}
      local base = lang_base(meta)
      local info = {}

      -- Title page: all people and the book citation
      local has_all = false
      doc.blocks = doc.blocks:filter(function(blk)
        if blk.t == 'Div' and blk.classes:includes('section-authors-all') then
          has_all = true
          return false
        end
        return true
      end)

      -- The former `sec-…:` block is no longer read
      for key, value in pairs(meta) do
        if key:match('^sec%-') and utils.type(value) == 'table' then
          warn('metadata "' .. key .. '" in ' .. quarto.doc.input_file
               .. ' is ignored; write author, date and date-modified at the top level')
        end
      end
      -- Quarto turns any other `citation` value into its own citation appendix
      if meta.citation ~= nil and meta.citation ~= false then
        warn('"citation" in ' .. quarto.doc.input_file .. ' only accepts false')
      end

      local reference
      local authors_found = false
      if has_all then
        info.names, info.label = all_authors(meta, base)
        reference = options.citation and format_book_citation(meta)
      elseif meta.author then
        -- Chapter: resolve the people for Quarto's title block
        local authors = meta_authors(meta.author)
        authors_found = #authors > 0
        meta['by-author'] = by_author(authors)
        if meta.labels then
          local plural = #authors >= 2
          meta.labels.authors = override(meta, plural and 'title-block-author-plural'
                                              or 'title-block-author-single')
                                or (plural and AUTHOR_PLURAL or AUTHOR_SINGLE)[base]
                                or (plural and AUTHOR_PLURAL or AUTHOR_SINGLE)['en']
        end
        if #authors > 0 and options.citation and meta.citation ~= false then
          reference = format_chapter_citation(authors, meta)
        end
      end

      if reference then
        info['citation-label'] = override(meta, 'section-title-citation')
                                 or CITATION[base] or CITATION['en']
        info.citation = pandoc.MetaBlocks(reference)
      end
      local license = (has_all or authors_found) and options.license
                      and license_inlines(options.license)
      if license then
        info['license-label'] = override(meta, 'section-title-reuse')
                                or LICENSE[base] or LICENSE['en']
        info.license = pandoc.MetaInlines(license)
      end
      if next(info) then meta['section-authors'] = info end
      return doc
    end
  }
}
