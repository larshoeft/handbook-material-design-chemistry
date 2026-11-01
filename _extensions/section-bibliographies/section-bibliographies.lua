--- section-bibliographies.lua – one bibliography per section
---
--- Based on section-bibliographies by Albert Krewinkel
--- (https://github.com/pandoc-ext/section-bibliographies, MIT License),
--- adapted for Quarto books: nested sections, Quarto cross-references,
--- inline citations linking to the nearest ancestor bibliography.
--- Usage: see README.md.

PANDOC_VERSION:must_be_at_least { 2, 19, 1 }

local EXTENSION_NAME            = 'section-bibliographies'

local List                      = require 'pandoc.List'
local utils                     = require 'pandoc.utils'
local citeproc, sha1, stringify = utils.citeproc, utils.sha1, utils.stringify

local function log_warning(message)
  local full_message = '[' .. EXTENSION_NAME .. '] ' .. message
  if quarto and quarto.log then
    quarto.log.warning(full_message)
  else
    io.stderr:write('WARNING ' .. full_message .. '\n')
  end
end

local make_sections
if PANDOC_VERSION >= '3.0' then
  make_sections = (require 'pandoc.structure').make_sections
else
  make_sections = function(doc, opts)
    return utils.make_sections(opts.number_sections, nil, doc.blocks)
  end
end

-- Metadata keys citeproc reads; everything else stays out of its runs
local CITEPROC_KEYS = {
  'csl', 'lang', 'link-citations', 'link-bibliography',
  'notes-after-punctuation', 'citation-abbreviations',
  'reference-section-title',
}

-- Quarto cross-reference prefixes; such citation IDs are not bibliography keys
local CROSSREF_PREFIXES = {
  sec = true, fig = true, tbl = true, eq = true, lst = true,
  thm = true, lem = true, cor = true, prp = true, cnj = true, def = true,
  exm = true, exr = true, sol = true, rem = true,
  nte = true, tip = true, wrn = true, imp = true, cau = true,
}

local function is_crossref_id(id)
  local prefix = id:match('^(%a+)%-')
  return prefix ~= nil and CROSSREF_PREFIXES[prefix] == true
end

local function is_section_div(div)
  return div.t == 'Div'
      and div.classes[1] == 'section'
      and (div.attributes.number or div.classes:includes 'unnumbered')
end

local function is_sectionrefs(blk)
  return blk.t == 'Div' and blk.classes:includes('sectionrefs')
end

local function is_refs_section(div)
  local c = div.content
  return is_section_div(div) and #c >= 2
      and c[1].t == 'Header' and is_sectionrefs(c[2])
end

local function flatten_sections(div)
  local header = is_section_div(div) and div.content[1]
  if not (header and header.t == 'Header') then return nil end
  header.identifier = div.identifier
  header.attributes.number = nil
  return div.content
end

local function deepcopy(tbl)
  if type(tbl) ~= 'table' then return tbl end
  local copy = {}
  for k, v in pairs(tbl) do copy[k] = deepcopy(v) end
  return copy
end

local function union(a, b)
  for id in pairs(b) do a[id] = true end
  return a
end

---Bibliography keys cited in blocks (cross-references excluded).
local function collect_cite_ids(blocks)
  local ids = {}
  pandoc.Blocks(blocks):walk {
    Cite = function(cite)
      for _, c in ipairs(cite.citations) do
        if not is_crossref_id(c.id) then ids[c.id] = true end
      end
    end,
  }
  return ids
end

local function rename_cites(blocks, suffix)
  return pandoc.Blocks(blocks):walk {
    Cite = function(cite)
      cite.citations = cite.citations:map(function(c)
        if not is_crossref_id(c.id) then c.id = c.id .. suffix end
        return c
      end)
      return cite
    end,
  }
end

local function restore_placeholders(blocks, processed)
  return blocks:map(function(blk)
    if blk.t == 'RawBlock' and blk.format == 'placeholder' then
      return processed[tonumber(blk.text)]
    end
    return blk
  end)
end

-- Hides cross-references from citeproc, which would report them as missing
local function citeproc_without_crossrefs(doc)
  local kept = {}
  local hidden = doc:walk {
    Cite = function(cite)
      for _, c in ipairs(cite.citations) do
        if not is_crossref_id(c.id) then return nil end
      end
      kept[#kept + 1] = cite
      return pandoc.RawInline('crossref-placeholder', tostring(#kept))
    end,
  }
  return citeproc(hidden):walk {
    RawInline = function(raw)
      if raw.format == 'crossref-placeholder' then
        return kept[tonumber(raw.text)]
      end
    end,
  }
end

-- ---------------------------------------------------------------------------
-- Section suffixes: section number, else a hash of the title, made unique
-- ---------------------------------------------------------------------------
local function make_suffixer()
  local used = {}
  return function(base)
    local suffix, i = base, 1
    while used[suffix] do
      i = i + 1
      suffix = base .. string.format('%x', i)
    end
    used[suffix] = true
    return '--' .. suffix
  end
end

-- ---------------------------------------------------------------------------
-- Split content: refs sections inlined, other subsections placeholdered
-- ---------------------------------------------------------------------------
local function split_content(content)
  local direct, subs, refs_header = List {}, {}, nil
  for _, blk in ipairs(content) do
    if is_refs_section(blk) then
      refs_header = blk.content[1]
      refs_header.attributes.number = nil
      -- make_sections moved the id to the section div
      if refs_header.identifier == '' then refs_header.identifier = blk.identifier end
      direct:extend(blk.content)
    elseif is_section_div(blk) then
      subs[#subs + 1] = blk
      direct:insert(pandoc.RawBlock('placeholder', tostring(#subs)))
    else
      direct:insert(blk)
    end
  end
  return direct, subs, refs_header
end

local function has_sectionrefs(blocks)
  for _, blk in ipairs(blocks) do
    if is_sectionrefs(blk) then return true end
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Processor
-- ---------------------------------------------------------------------------
local function make_processor(meta, references)
  local suffixer = make_suffixer()

  ---Metadata for one citeproc run: only the cited references, renamed.
  local function citeproc_meta(ids, suffix)
    local m = {}
    for _, key in ipairs(CITEPROC_KEYS) do m[key] = meta[key] end
    m.references = List {}
    for _, ref in ipairs(references) do
      if ids[ref.id] then
        local copy = deepcopy(ref)
        copy.id = ref.id .. suffix
        m.references:insert(copy)
      end
    end
    return m
  end

  ---Citeproc with the bibliography in the section's sectionrefs div.
  ---`extra_ids` are keys cited in subsections, listed via nocite.
  local function render_with_bibliography(direct, suffix, extra_ids)
    local ids = union(collect_cite_ids(direct), extra_ids)
    local blocks = rename_cites(direct, suffix):walk {
      Div = function(div)
        if is_sectionrefs(div) then
          div.identifier = 'refs'
          return div
        end
      end,
    }
    local m = citeproc_meta(ids, suffix)
    local nocite = List {}
    for id in pairs(extra_ids) do
      nocite:insert(pandoc.Citation(id .. suffix, 'NormalCitation'))
    end
    if #nocite > 0 then
      m.nocite = pandoc.Inlines { pandoc.Cite(pandoc.Inlines {}, nocite) }
    end
    return citeproc_without_crossrefs(pandoc.Pandoc(blocks, m)).blocks:walk {
      Header = function(h)
        if h.identifier == 'bibliography' then
          h.identifier = 'bibliography' .. suffix
          return h
        end
      end,
      Div = function(d)
        if d.identifier == 'refs' then
          d.identifier = 'refs' .. suffix
          return d
        end
      end,
    }
  end

  ---Citeproc for inline citations only; they link to the bibliography of
  ---the section with `suffix`. Citeproc links only to entries it renders,
  ---so it renders them into a scratch div that is dropped afterwards.
  local function render_inline(direct, suffix, ids)
    local m = citeproc_meta(ids, suffix)
    m['reference-section-title'] = nil
    local blocks = rename_cites(direct, suffix)
    blocks:insert(pandoc.Div({}, pandoc.Attr('refs', { 'section-bibs-scratch' })))
    return citeproc_without_crossrefs(pandoc.Pandoc(blocks, m)).blocks:filter(function(blk)
      return not (blk.t == 'Div' and blk.classes:includes('section-bibs-scratch'))
    end)
  end

  ---Renders one block list (a section's content or the document root).
  ---Returns the new blocks and the bibliography keys cited in them.
  local function render(content, title, own_suffix, anc_suffix, process)
    local direct, subs, refs_header = split_content(content)
    local here = has_sectionrefs(direct)
    local target_suffix = here and own_suffix or anc_suffix

    if here and not refs_header then
      log_warning('"::: sectionrefs" in section "' .. title .. '" has no ' ..
        'heading of its own (e.g. "### Quellen"); the bibliography only ' ..
        'covers this section, citations in sibling sections will not link.')
    end

    local processed, sub_ids = {}, {}
    for i, sub in ipairs(subs) do
      local block, ids = process(sub, target_suffix)
      processed[i] = block
      union(sub_ids, ids)
    end

    local own_ids = collect_cite_ids(direct)
    local all_ids = union(union({}, own_ids), sub_ids)

    if here and not next(all_ids) then
      -- Nothing cited: drop the empty bibliography and its heading
      local refs_id = refs_header and refs_header.identifier
      direct = direct:filter(function(blk)
        return not is_sectionrefs(blk)
            and not (blk.t == 'Header' and refs_id and blk.identifier == refs_id)
      end)
    elseif here then
      direct = render_with_bibliography(direct, own_suffix, sub_ids)
    elseif next(own_ids) then
      if not target_suffix then
        log_warning('citations in section "' .. title .. '" have no ' ..
          '"::: sectionrefs" bibliography in an enclosing section; ' ..
          'their links will not resolve.')
      end
      direct = render_inline(direct, target_suffix or own_suffix, own_ids)
    end

    return restore_placeholders(direct, processed), all_ids
  end

  local process
  process = function(div, anc_suffix)
    local header = div.content[1]
    if not (header and header.t == 'Header') then return div, {} end
    local base = header.attributes.number or sha1(stringify(header.content)):sub(1, 12)
    local content, ids = render(div.content, stringify(header.content),
      suffixer(base), anc_suffix, process)
    div.content = content
    return div, ids
  end

  local function process_root(blocks, title)
    local suffix = suffixer(sha1(title):sub(1, 12))
    return (render(blocks, title, suffix, nil, process))
  end

  return process, process_root
end

-- ---------------------------------------------------------------------------
-- Cleanup: remove results from a previous filter run
-- ---------------------------------------------------------------------------
local remove_previous_results = {
  Header = function(h)
    if h.identifier == 'bibliography' or h.identifier:match('^bibliography%-%-') then
      return {}
    end
  end,
  Cite = function(cite)
    cite.citations = cite.citations:map(function(c)
      c.id = c.id:gsub('%-%-[%x]+$', ''):gsub('%-%-[%d%.]+$', '')
      return c
    end)
    return cite
  end,
  Div = function(d)
    if is_sectionrefs(d) then
      d.identifier = ''
      d.content = pandoc.Blocks {}
      return d
    end
    if d.identifier:match('^ref%-') or d.classes:includes('csl-bib-body') then
      return {}
    end
  end,
}

local function get_options(meta)
  local opts = meta['section-bibliographies'] or {}
  opts.bibliography = opts.bibliography
      or meta['section-bibs-bibliography']
      or meta['bibliography']
  opts.references = opts.references or meta['references']
  return opts
end

-- ---------------------------------------------------------------------------
-- Entry point
-- ---------------------------------------------------------------------------
return {
  {
    Pandoc = function(doc)
      local opts = get_options(doc.meta)

      if opts['cleanup-first'] then
        doc = doc:walk(remove_previous_results)
      end

      -- `lang` decides how titles of entries without langid are cased
      local refmeta = {
        lang         = doc.meta.lang,
        bibliography = deepcopy(opts.bibliography),
        references   = deepcopy(opts.references),
        nocite       = pandoc.Inlines {
          pandoc.Cite('@*', { pandoc.Citation('*', 'NormalCitation') })
        },
      }
      local references = utils.references(pandoc.Pandoc({}, refmeta))
      if not next(references) then return doc end

      local process, process_root = make_processor(doc.meta, references)
      local sectioned = make_sections(doc, { number_sections = true })

      local has_h1 = false
      for _, blk in ipairs(sectioned) do
        local h = is_section_div(blk) and blk.content[1]
        if h and h.t == 'Header' and h.level == 1 then
          has_h1 = true
          break
        end
      end

      local result
      if has_h1 then
        result = List(sectioned):map(function(blk)
          return is_section_div(blk) and (process(blk)) or blk
        end)
      else
        local title = doc.meta.title and stringify(doc.meta.title) or ''
        result = process_root(sectioned, title)
      end

      doc.blocks = pandoc.Blocks(result):walk { Div = flatten_sections }
      return doc
    end
  }
}
