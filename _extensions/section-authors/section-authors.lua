--- section-authors.lua
--- Author/date block, license and citation below each ## heading of a
--- Quarto book, from heading attributes or a `sec-…:` metadata entry.
--- `::: section-authors-all` lists all people in the title block.
--- Usage and options: see README.md.

--- Extension name, used for log messages and the HTML dependency
local EXTENSION_NAME = 'section-authors'

--- Extension version (keep in sync with _extension.yml)
local EXTENSION_VERSION = '0.8.1'

--- Load required modules
local List  = require 'pandoc.List'
local utils = require 'pandoc.utils'

-- ---------------------------------------------------------------------------
-- Constants
-- ---------------------------------------------------------------------------

--- Keys allowed in a section's metadata entry
---@type table<string, boolean>
local SECTION_KEYS = { author = true, date = true,
                       ['date-modified'] = true, license = true,
                       citation = true }

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

-- Quarto's `title-block-published` per language; extend as needed.
local PUBLISHED = {
  de = 'Veröffentlicht',
  en = 'Published',
}

-- Label for `date-modified` per language; extend as needed.
-- (Quarto's own `title-block-modified` reads "Geändert" / "Modified".)
local MODIFIED = {
  de = 'Aktualisiert',
  en = 'Updated',
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
    modified  = override(meta, 'title-block-modified')
                or MODIFIED[base] or MODIFIED['en'],
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

---Web address of the current page from `book.site-url` (or `site-url`),
---optionally with an anchor.
---@param meta Meta document metadata
---@param anchor string|nil section id
---@return string|nil
local function page_url(meta, anchor)
  local book = utils.type(meta.book) == 'table' and meta.book or {}
  local base = book['site-url'] or meta['site-url']
  if not base or not (quarto.project and quarto.project.directory) then return nil end
  base = utils.stringify(base):gsub('/*$', '/')
  local page = pandoc.path.make_relative(quarto.doc.input_file, quarto.project.directory)
  page = page:gsub('\\', '/'):gsub('%.qmd$', '.html')
  if page == 'index.html' then page = '' end
  return base .. page .. (anchor and ('#' .. anchor) or '')
end

---Format one CSL item with citeproc (using the document's `csl` and
---`lang`) and keep only the entry's content: ids and classes like `ref-…`
---and `csl-bib-body` would be picked up by section-bibliographies.
---@param item table CSL item
---@param meta Meta document metadata
---@param what string what is cited, for the warning
---@return Blocks|nil formatted reference, nil on failure
local function run_citeproc(item, meta, what)
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
    warn('citation for ' .. what .. ' failed: ' .. tostring(result))
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

---Format the section's `citation` metadata with citeproc. Missing title,
---author and issued are taken from the heading, the section authors and
---the section date; for `type: chapter`, missing container-title and
---editor from the book title (see book_title) and `book.author`.
---@param citation MetaValue|boolean `citation` entry (`true` = defaults)
---@param header Header the section heading
---@param authors table[] section authors (see meta_authors)
---@param date string|nil section date as written in the source
---@param meta Meta document metadata
---@return Blocks|nil formatted reference, nil on failure
local function format_citation(citation, header, authors, date, meta)
  local item = {}
  if utils.type(citation) == 'table' then  -- `citation: true` = defaults only
    for k, v in pairs(citation) do item[k] = v end
  end
  item.type  = item.type and utils.stringify(item.type) or 'chapter'
  item.title = item.title or utils.stringify(header.content)
  item.issued = item.issued or date

  item.author = csl_names(item.author or authors)

  -- `book.author` holds the book's editors
  if item.type == 'chapter' then
    local book = utils.type(meta.book) == 'table' and meta.book or {}
    item['container-title'] = item['container-title'] or book_title(book)
    item.editor = csl_names(item.editor or book.author)
  end
  item.URL = item.URL or page_url(meta, header.identifier)

  return run_citeproc(item, meta, '#' .. header.identifier)
end

---Citation of the whole book (editors from `book.author`), for the title
---block next to `::: section-authors-all`.
---@param meta Meta document metadata
---@return Blocks|nil formatted reference, nil on failure
local function format_book_citation(meta)
  local book = utils.type(meta.book) == 'table' and meta.book or {}
  local date = book.date or meta.date
  local year = date and utils.stringify(date):match('%d%d%d%d') or os.date('%Y')
  return run_citeproc({
    type   = 'book',
    title  = book_title(book),
    editor = csl_names(book.author),
    issued = year,
    URL    = page_url(meta),
  }, meta, 'the book')
end

---One labelled field (label + contents), like Quarto's title block.
---@param label string
---@param contents Block
---@param class string|nil class of the field, e.g. for its column
---@return Div
local function field(label, contents, class)
  return pandoc.Div({
    pandoc.Div(pandoc.Plain(pandoc.Str(label)),
      pandoc.Attr('', { 'section-authors-label' })),
    contents,
  }, pandoc.Attr('', { class }))
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

---Build the author/date block for a section.
---Uses plain Pandoc elements (escaped by the writer, usable in every
---output format); HTML styling comes from section-authors.css.
---The two-column grid keeps authors and license on the left, the
---publication and revision dates on the right.
---@param authors table[] author records (may be empty)
---@param date string|nil formatted publication date
---@param modified string|nil formatted revision date
---@param labels table labels from get_labels
---@param reference Blocks|nil formatted citation
---@param license Inlines|nil license text or link
---@return Div
local function author_block(authors, date, modified, labels, reference,
                            license)
  local fields = List {}
  if #authors > 0 then
    local names = pandoc.Inlines {}
    for i, author in ipairs(authors) do
      if i > 1 then names:extend { pandoc.Str(','), pandoc.Space() } end
      names:insert(pandoc.Span(author_inlines(author),
        pandoc.Attr('', { 'section-authors-name' })))
    end
    local label = (#authors >= 2) and labels.plural or labels.single
    fields:insert(field(label,
      pandoc.Div(pandoc.Plain(names),
        pandoc.Attr('', { 'section-authors-names' }))))
  end
  if date then
    fields:insert(field(labels.published,
      pandoc.Div(pandoc.Plain(pandoc.Str(date)),
        pandoc.Attr('', { 'section-authors-date' })), 'section-authors-right'))
  end
  if license then
    fields:insert(field(labels.license,
      pandoc.Div(pandoc.Plain(license),
        pandoc.Attr('', { 'section-authors-license' }))))
  end
  if modified then
    fields:insert(field(labels.modified,
      pandoc.Div(pandoc.Plain(pandoc.Str(modified)),
        pandoc.Attr('', { 'section-authors-modified' })),
      'section-authors-right'))
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
local default_citation = nil
local default_license = nil

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
---URLs without a scheme
---("www.example.org") get "https://".
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
---@param id string section id, for warnings
---@return table|nil record with name, email, orcid, affiliations
local function author_record(item, id)
  if not item.name then
    warn('author without "name" in metadata "' .. id .. '"')
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
      warn('ORCID "' .. orcid .. '" of ' .. author.name .. ' in #' .. id
           .. ' is not 0000-0000-0000-0000; ignored')
    else
      author.orcid = orcid
    end
  end
  author.affiliations = affiliation_list(item.affiliation
                                         or item.affiliations)
  return author
end

local function known_author(ref, id)
  local item = known_authors[ref]
  return item and author_record(item, id)
end

-- A single unknown word is likely a mistyped id
local function author_from_string(name, id)
  local author = known_author(name, id)
  if author then return author end
  if not name:match('%s') then
    warn('author "' .. name .. '" in #' .. id .. ' is no known id and no '
         .. 'full name; check "book.author" and "contributors"')
  end
  return { name = name }
end

---Parse a comma-separated author string into a list of author records.
---@param str string
---@param id string section id, for warnings
---@return table[]
local function parse_authors(str, id)
  local authors = {}
  for name in str:gmatch('[^,]+') do
    name = name:match('^%s*(.-)%s*$')
    if name ~= '' then
      authors[#authors + 1] = author_from_string(name, id)
    end
  end
  return authors
end

---Author records from a metadata value: a name or id, a Quarto author
---map, a `ref` map, a list of these, or a comma-separated string.
---@param value MetaValue|nil
---@param id string section id, for warnings
---@return table[]
local function meta_authors(value, id)
  if value == nil then return {} end
  local kind = utils.type(value)
  if kind == 'table' then value = { value } end  -- one author map
  if kind == 'List' or kind == 'table' then
    local authors = {}
    for _, item in ipairs(value) do
      local author
      if utils.type(item) == 'table' and item.ref then
        local ref = utils.stringify(item.ref)
        author = known_author(ref, id)
        if not author then
          warn('unknown author ref "' .. ref .. '" in #' .. id)
        end
      elseif utils.type(item) == 'table' then
        author = author_record(item, id)
      else
        local name = utils.stringify(item)
        if name:match('@') or name:match(ORCID_PATTERN) then
          warn('author "' .. name .. '" in #' .. id .. ' looks like an '
               .. 'e-mail or ORCID; use "name:", "email:" and "orcid:"')
        end
        author = author_from_string(name, id)
      end
      if author then authors[#authors + 1] = author end
    end
    return authors
  end
  return parse_authors(utils.stringify(value), id)
end

---All people in `book.author` and `contributors`, sorted by family name,
---as metadata for the title block partial (see title-metadata.html).
---The label ignores the title-block overrides, which name the editors.
---@param meta Meta document metadata
---@param base string base language code
---@return table `label` and `names`
local function all_authors(meta, base)
  local authors = List {}
  local book = utils.type(meta.book) == 'table' and meta.book or {}
  for _, value in ipairs({ book.author, meta.contributors }) do
    if utils.type(value) == 'List' then
      for _, item in ipairs(value) do
        local author = utils.type(item) == 'table'
                       and author_record(item, 'section-authors-all')
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
  return {
    label = labels[base] or labels['en'],
    names = pandoc.MetaBlocks { pandoc.Para(names) },
  }
end

---Metadata entry for a section id (a map under that top-level key).
---@param meta Meta document metadata
---@param id string section id
---@return table|nil
local function section_entry(meta, id)
  if id == '' then return nil end
  local entry = meta[id]
  return utils.type(entry) == 'table' and entry or nil
end

---Warn about keys a section entry does not support (likely typos).
---@param id string section id
---@param entry table section metadata entry
local function validate_entry(id, entry)
  for key in pairs(entry) do
    if not SECTION_KEYS[key] then
      warn('unknown key "' .. key .. '" in metadata "' .. id
           .. '"; supported: author, date, date-modified, license, '
           .. 'citation')
    end
  end
end

---Author names, dates, citation metadata and license for a ## heading.
---Heading attributes take precedence over the metadata entry for the
---heading's id; the citation comes from the metadata only.
---@param blk Header
---@param meta Meta document metadata
---@return table[] authors
---@return string|nil date
---@return string|nil modified
---@return MetaValue|nil citation
---@return Inlines|nil license
local function section_info(blk, meta)
  local entry   = section_entry(meta, blk.identifier) or {}
  validate_entry(blk.identifier, entry)
  local attrs   = blk.attributes
  local authors = (attrs.author and attrs.author ~= '')
                  and parse_authors(attrs.author, blk.identifier)
                  or meta_authors(entry.author, blk.identifier)
  local function date_of(key)
    local value = (attrs[key] and attrs[key] ~= '') and attrs[key]
                  or (entry[key] and utils.stringify(entry[key]))
    if value then
      -- Accept unpadded month/day ("2026-10-3" -> "2026-10-03")
      local y, m, d = value:match('^(%d%d%d%d)%-(%d%d?)%-(%d%d?)$')
      if y then
        value = string.format('%s-%02d-%02d', y, tonumber(m), tonumber(d))
      else
        warn(key .. ' "' .. value .. '" of #' .. blk.identifier
             .. ' is not YYYY-MM-DD; shown as written')
      end
    end
    attrs[key] = nil
    return value
  end
  local date     = date_of('date')
  local modified = date_of('date-modified')
  local license = (attrs.license and attrs.license ~= '') and attrs.license
                  or entry.license
                  or (next(authors) and default_license)
  attrs.author  = nil
  attrs.license = nil
  local citation = entry.citation
  if citation == nil and next(authors) then citation = default_citation end
  return authors, date, modified, citation,
         license and license_inlines(license)
end

-- ---------------------------------------------------------------------------
-- Extension registration
-- ---------------------------------------------------------------------------

return {
  {
    Pandoc = function(doc)
      add_css()
      local book = doc.meta.book
      known_authors = index_by_id(
        utils.type(book) == 'table' and book.author or nil)
      index_by_id(doc.meta.contributors, known_authors)
      local options = doc.meta.extensions
                      and doc.meta.extensions[EXTENSION_NAME]
      default_citation = options and options.citation or nil
      default_license = options and options.license or nil
      known_affiliations = index_by_id(doc.meta.affiliations)
      local base         = lang_base(doc.meta)
      local labels       = get_labels(doc.meta, base)
      local blocks       = doc.blocks
      local new_blocks   = List {}
      local seen         = {}

      for i = 1, #blocks do
        local blk = blocks[i]
        if blk.t == 'Header' and blk.level == 2 then
          seen[blk.identifier] = true
          local authors, date, modified, citation, license =
            section_info(blk, doc.meta)
          local reference = citation
            and format_citation(citation, blk, authors, date, doc.meta)
          new_blocks:insert(blk)
          if #authors > 0 or date or modified or reference or license then
            new_blocks:insert(author_block(authors,
              date and format_date(date, base),
              modified and format_date(modified, base),
              labels, reference, license))
          end
        elseif blk.t == 'Div' and blk.classes:includes('section-authors-all') then
          local all = all_authors(doc.meta, base)
          local reference = default_citation and format_book_citation(doc.meta)
          if reference then
            all['citation-label'] = labels.citation
            all.citation = pandoc.MetaBlocks(reference)
          end
          local license = default_license and license_inlines(default_license)
          if license then
            all['license-label'] = labels.license
            all.license = pandoc.MetaInlines(license)
          end
          doc.meta['section-authors-all'] = all
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
