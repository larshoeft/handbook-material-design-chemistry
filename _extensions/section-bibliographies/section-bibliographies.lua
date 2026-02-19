--- section-bibliographies - scope-aware per-section reference sections
---
--- Works with Quarto book chapters where the H1 title is removed from blocks.
--- Top-level blocks (outside any section div) are treated as a virtual root
--- section and processed if they contain a sectionrefs div.

PANDOC_VERSION:must_be_at_least {2,19,1}

local List  = require 'pandoc.List'
local utils = require 'pandoc.utils'
local citeproc, sha1, stringify = utils.citeproc, utils.sha1, utils.stringify

local make_sections
if PANDOC_VERSION >= '3.0' then
  make_sections = (require 'pandoc.structure').make_sections
else
  make_sections = function(doc, opts)
    return utils.make_sections(opts.number_sections, nil, doc.blocks)
  end
end

-- ---------------------------------------------------------------------------
-- Helpers
-- ---------------------------------------------------------------------------

local function is_section_div(div)
  return div.t == 'Div'
    and div.classes[1] == 'section'
    and (div.attributes.number or div.classes:includes 'unnumbered')
end

local function section_header(div)
  local header = div.content and div.content[1]
  if not (is_section_div(div) and header and header.t == 'Header') then
    return nil, nil
  end
  local suffix = header.attributes.number or sha1(stringify(header.content))
  return header, '--' .. suffix
end

local function flatten_sections(div)
  local header = section_header(div)
  if not header then return nil end
  header.identifier = div.identifier
  header.attributes.number = nil
  div.content[1] = header
  return div.content
end

local function deepcopy(tbl)
  if type(tbl) ~= 'table' then return tbl end
  local copy = {}
  for k, v in pairs(tbl) do copy[k] = deepcopy(v) end
  return copy
end

--- A section div is a "refs section" if its only content is [Header, sectionrefs]
local function is_refs_section(div)
  if not is_section_div(div) then return false end
  local c = div.content
  if #c ~= 2 then return false end
  if c[1].t ~= 'Header' then return false end
  if c[2].t ~= 'Div' then return false end
  return c[2].classes:includes('sectionrefs')
end

-- ---------------------------------------------------------------------------
-- Run citeproc on a flat block list containing a sectionrefs div
-- ---------------------------------------------------------------------------
local function run_citeproc_for_section(blocks, suffix, meta, references)
  local renamed = pandoc.Blocks(blocks):walk {
    Cite = function(cite)
      cite.citations = cite.citations:map(function(c)
        c.id = c.id .. suffix
        return c
      end)
      return cite
    end,
    Div = function(div)
      if div.classes:includes('sectionrefs') then
        div.identifier = 'refs'
        return div
      end
    end,
  }

  local newmeta = deepcopy(meta)
  newmeta.bibliography = nil
  newmeta.nocite = nil
  newmeta.references = deepcopy(references)
  for i, ref in ipairs(newmeta.references) do
    newmeta.references[i].id = ref.id .. suffix
  end

  local result = citeproc(pandoc.Pandoc(renamed, newmeta)).blocks

  return result:walk {
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

local function has_sectionrefs(blocks)
  for _, blk in ipairs(blocks) do
    if blk.t == 'Div' and blk.classes:includes('sectionrefs') then
      return true
    end
  end
  return false
end

-- ---------------------------------------------------------------------------
-- Split content: refs-sections inlined, normal subsections placeholdered
-- ---------------------------------------------------------------------------
local function split_content(content)
  local direct = List{}
  local subs   = {}
  local n      = 0
  for _, blk in ipairs(content) do
    if is_section_div(blk) then
      if is_refs_section(blk) then
        direct:insert(blk.content[2])  -- inline the sectionrefs div
      else
        n = n + 1
        subs[n] = blk
        direct:insert(pandoc.RawBlock('placeholder', tostring(n)))
      end
    else
      direct:insert(blk)
    end
  end
  return direct, subs, n
end

-- ---------------------------------------------------------------------------
-- Main recursive processor (bottom-up)
-- ---------------------------------------------------------------------------
local function make_processor(meta, references)
  local process

  process = function(div)
    local header, suffix = section_header(div)
    if not header or not suffix then return div end

    local direct, subs, nsubs = split_content(div.content)

    local processed_subs = {}
    for i = 1, nsubs do
      processed_subs[i] = process(subs[i])
    end

    if has_sectionrefs(direct) then
      direct = run_citeproc_for_section(direct, suffix, meta, references)
    end

    div.content = direct:map(function(blk)
      if blk.t == 'RawBlock' and blk.format == 'placeholder' then
        return processed_subs[tonumber(blk.text)]
      end
      return blk
    end)

    return div
  end

  -- Also process a flat block list as a virtual root section
  -- (for Quarto chapters where H1 is stripped into title metadata)
  local function process_root(blocks, root_suffix)
    local direct = List{}
    local subs   = {}
    local n      = 0

    for _, blk in ipairs(blocks) do
      if is_section_div(blk) then
        if is_refs_section(blk) then
          direct:insert(blk.content[2])
        else
          n = n + 1
          subs[n] = blk
          direct:insert(pandoc.RawBlock('placeholder', tostring(n)))
        end
      else
        direct:insert(blk)
      end
    end

    local processed_subs = {}
    for i = 1, n do
      processed_subs[i] = process(subs[i])
    end

    if has_sectionrefs(direct) then
      direct = run_citeproc_for_section(direct, root_suffix, meta, references)
    end

    return direct:map(function(blk)
      if blk.t == 'RawBlock' and blk.format == 'placeholder' then
        return processed_subs[tonumber(blk.text)]
      end
      return blk
    end)
  end

  return process, process_root
end

-- ---------------------------------------------------------------------------
-- Cleanup
-- ---------------------------------------------------------------------------
local remove_previous_results = {
  Header = function(h)
    if h.identifier == 'bibliography' or h.identifier:match('^bibliography%-%-') then
      return {}
    end
  end,
  Div = function(d)
    if d.classes:includes('sectionrefs') then
      d.identifier = ''
      d.content = pandoc.Blocks{}
      return d
    end
    if d.identifier:match('^ref%-') or d.classes:includes('csl-bib-body') then
      return {}
    end
  end,
}

-- ---------------------------------------------------------------------------
-- Options
-- ---------------------------------------------------------------------------
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

      -- Pre-load all references once
      local newmeta = deepcopy(doc.meta)
      newmeta.bibliography = deepcopy(opts.bibliography)
      newmeta.references   = deepcopy(opts.references)
      newmeta.nocite = pandoc.Inlines{
        pandoc.Cite('@*', {pandoc.Citation('*', 'NormalCitation')})
      }
      local references = utils.references(pandoc.Pandoc({}, newmeta))
      if not next(references) then return doc end

      local process, process_root = make_processor(doc.meta, references)

      -- Build a suffix for the root level from the document title
      local title = doc.meta.title and stringify(doc.meta.title) or ''
      local root_suffix = '--' .. (sha1(title .. tostring(os.time())):sub(1,8))

      local sectioned = make_sections(doc, {number_sections = true})

      -- Check if H1 exists: if so, use normal top-down section processing
      -- If not (Quarto stripped it), use process_root on the flat block list
      local has_h1 = false
      for _, blk in ipairs(sectioned) do
        if is_section_div(blk) then
          local h = blk.content[1]
          if h and h.t == 'Header' and h.level == 1 then
            has_h1 = true
            break
          end
        end
      end

      if has_h1 then
        -- Normal processing: top-level section divs are H1 chapters
        doc.blocks = sectioned
          :walk {
            traverse = 'topdown',
            Div = function(div)
              if is_section_div(div) then
                return process(div), false
              end
            end
          }
          :walk { Div = flatten_sections }
      else
        -- Quarto stripped H1: process flat block list as virtual root
        local result = process_root(sectioned, root_suffix)
        -- flatten any remaining section divs
        doc.blocks = pandoc.Blocks(result):walk { Div = flatten_sections }
      end

      return doc
    end
  }
}
