PANDOC_VERSION:must_be_at_least { 2, 19, 1 }

local List                      = require 'pandoc.List'
local utils                     = require 'pandoc.utils'
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

-- Returns true if the citation ID is a Quarto cross-reference, not a
-- bibliography key. Cross-refs start with sec-, fig-, tbl-, eq-, lst-, thm-
local function is_crossref_id(id)
  return id:match('^sec%-')
      or id:match('^fig%-')
      or id:match('^tbl%-')
      or id:match('^eq%-')
      or id:match('^lst%-')
      or id:match('^thm%-')
end

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

local function is_refs_section(div)
  if not is_section_div(div) then return false end
  local c = div.content
  if #c < 2 then return false end
  if c[1].t ~= 'Header' then return false end
  if c[2].t ~= 'Div' then return false end
  return c[2].classes:includes('sectionrefs')
end

-- ---------------------------------------------------------------------------
-- Collect raw citation IDs from a block list (recursively)
-- Excludes Quarto cross-reference IDs (sec-, fig-, tbl-, eq-, lst-, thm-)
-- ---------------------------------------------------------------------------
local function collect_cite_ids(blocks)
  local ids = {}
  pandoc.Blocks(blocks):walk {
    Cite = function(cite)
      for _, c in ipairs(cite.citations) do
        if not is_crossref_id(c.id) then
          ids[c.id] = true
        end
      end
    end
  }
  return ids
end

-- ---------------------------------------------------------------------------
-- Collect all (possibly suffixed) citation IDs from a processed block tree
-- ---------------------------------------------------------------------------
local function collect_suffixed_ids(blocks)
  local ids = {}
  pandoc.Blocks(blocks):walk {
    Cite = function(cite)
      for _, c in ipairs(cite.citations) do
        if not is_crossref_id(c.id) then
          ids[c.id] = true
        end
      end
    end
  }
  return ids
end

-- ---------------------------------------------------------------------------
-- Run citeproc on a flat block list containing a sectionrefs div.
-- extra_ids: {id -> true} of IDs from preceding siblings/children.
-- ---------------------------------------------------------------------------
local function run_citeproc_for_section(blocks, suffix, meta, references, extra_ids)
  local renamed = pandoc.Blocks(blocks):walk {
    Cite = function(cite)
      cite.citations = cite.citations:map(function(c)
        if not is_crossref_id(c.id) then
          c.id = c.id .. suffix
        end
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

  if extra_ids and next(extra_ids) then
    local nocite_cites = List {}
    for id, _ in pairs(extra_ids) do
      if not is_crossref_id(id) then
        local base_id = id:gsub('%-%-[%x]+$', ''):gsub('%-%-[%d%.]+$', '')
        nocite_cites:insert(pandoc.Citation(base_id .. suffix, 'NormalCitation'))
      end
    end
    if #nocite_cites > 0 then
      local nocite_inline = pandoc.Cite(
        pandoc.Inlines { pandoc.Str('') },
        nocite_cites
      )
      newmeta.nocite = pandoc.Inlines { nocite_inline }
    end
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

-- ---------------------------------------------------------------------------
-- Run citeproc on blocks WITHOUT a sectionrefs div (inline-citations only).
-- Crossref IDs are left unchanged; only bib keys get the suffix.
-- ---------------------------------------------------------------------------
local function run_citeproc_inline_only(blocks, suffix, meta, references)
  local renamed = pandoc.Blocks(blocks):walk {
    Cite = function(cite)
      cite.citations = cite.citations:map(function(c)
        if not is_crossref_id(c.id) then
          c.id = c.id .. suffix
        end
        return c
      end)
      return cite
    end,
  }

  local newmeta = deepcopy(meta)
  newmeta.bibliography = nil
  newmeta.nocite = nil
  newmeta.references = deepcopy(references)
  for i, ref in ipairs(newmeta.references) do
    newmeta.references[i].id = ref.id .. suffix
  end

  -- Run citeproc – this resolves inline Cite nodes to formatted links.
  -- citeproc will also produce a bibliography div, but we strip it afterwards.
  local result = citeproc(pandoc.Pandoc(renamed, newmeta)).blocks

  -- Remove any generated bibliography divs and the References header
  -- (we don't want them here – bibliography appears only in sectionrefs)
  local in_refs_header = false
  return result:filter(function(blk)
    -- Remove the auto-generated "References" header from citeproc
    if blk.t == 'Header' and (
          blk.identifier == 'bibliography' or
          blk.identifier:match('^bibliography') or
          blk.identifier == 'references' or
          blk.identifier:match('^references')
        ) then
      return false
    end
    -- Remove the refs div itself
    if blk.t == 'Div' and (
          blk.identifier == 'refs' or
          blk.classes:includes('csl-bib-body')
        ) then
      return false
    end
    return true
  end)
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
-- Split content: refs-sections inlined, normal subsections placeholdered.
-- ---------------------------------------------------------------------------
local function split_content(content)
  local direct = List {}
  local subs   = {}
  local n      = 0
  for _, blk in ipairs(content) do
    if is_section_div(blk) then
      if is_refs_section(blk) then
        local ref_header = blk.content[1]
        ref_header.attributes.number = nil
        direct:insert(ref_header)
        for ci = 2, #blk.content do
          direct:insert(blk.content[ci])
        end
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
    if not header or not suffix then return div, {} end

    local direct, subs, nsubs = split_content(div.content)

    -- Check if any subsection has sectionrefs (so siblings need inline rendering)
    local any_sub_has_refs = false
    for i = 1, nsubs do
      if has_sectionrefs(subs[i].content or {}) then
        any_sub_has_refs = true
        break
      end
    end

    -- Process all subsections first (bottom-up), collecting their citation IDs
    local processed_subs = {}
    local sub_ids = {}
    for i = 1, nsubs do
      local processed_sub, sub_id_set = process(subs[i])
      processed_subs[i] = processed_sub
      for id, _ in pairs(sub_id_set) do
        sub_ids[id] = true
      end
    end

    if has_sectionrefs(direct) then
      -- Rename + run citeproc with full bibliography output.
      direct = run_citeproc_for_section(direct, suffix, meta, references, sub_ids)

      div.content = direct:map(function(blk)
        if blk.t == 'RawBlock' and blk.format == 'placeholder' then
          return processed_subs[tonumber(blk.text)]
        end
        return blk
      end)

      local all_ids = collect_suffixed_ids(div.content)
      return div, all_ids
    else
      -- No sectionrefs on this level.
      -- If any sub had sectionrefs, all subs without sectionrefs have already
      -- been processed (their inline cites rendered) inside process() recursion.
      -- We still need to render inline cites in `direct` (the non-sub content).
      local raw_ids = collect_cite_ids(direct)

      -- If there are inline citations in direct content, run citeproc on them
      -- (inline-only, no bibliography) so they render as links.
      if next(raw_ids) then
        direct = run_citeproc_inline_only(direct, suffix, meta, references)
      end

      -- Build suffixed versions of raw_ids for parent accumulation
      local suffixed_raw_ids = {}
      for id, _ in pairs(raw_ids) do
        suffixed_raw_ids[id .. suffix] = true
      end
      -- Also include suffixed IDs from children
      for id, _ in pairs(sub_ids) do
        suffixed_raw_ids[id] = true
      end

      div.content = direct:map(function(blk)
        if blk.t == 'RawBlock' and blk.format == 'placeholder' then
          return processed_subs[tonumber(blk.text)]
        end
        return blk
      end)

      return div, suffixed_raw_ids
    end
  end

  local function process_root(blocks, root_suffix)
    local direct = List {}
    local subs   = {}
    local n      = 0

    for _, blk in ipairs(blocks) do
      if is_section_div(blk) then
        if is_refs_section(blk) then
          local ref_header = blk.content[1]
          ref_header.attributes.number = nil
          direct:insert(ref_header)
          for ci = 2, #blk.content do
            direct:insert(blk.content[ci])
          end
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
    local sub_ids = {}
    for i = 1, n do
      local processed_sub, sub_id_set = process(subs[i])
      processed_subs[i] = processed_sub
      for id, _ in pairs(sub_id_set) do
        sub_ids[id] = true
      end
    end

    if has_sectionrefs(direct) then
      direct = run_citeproc_for_section(direct, root_suffix, meta, references, sub_ids)
    else
      -- Render inline citations in root direct content
      local raw_ids = collect_cite_ids(direct)
      if next(raw_ids) then
        direct = run_citeproc_inline_only(direct, root_suffix, meta, references)
      end
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
    if d.classes:includes('sectionrefs') then
      d.identifier = ''
      d.content = pandoc.Blocks {}
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

      local newmeta        = deepcopy(doc.meta)
      newmeta.bibliography = deepcopy(opts.bibliography)
      newmeta.references   = deepcopy(opts.references)
      newmeta.nocite       = pandoc.Inlines {
        pandoc.Cite('@*', { pandoc.Citation('*', 'NormalCitation') })
      }
      local references     = utils.references(pandoc.Pandoc({}, newmeta))
      if not next(references) then return doc end

      local process, process_root = make_processor(doc.meta, references)

      local title = doc.meta.title and stringify(doc.meta.title) or ''
      local root_suffix = '--' .. (sha1(title .. tostring(os.time())):sub(1, 8))

      local sectioned = make_sections(doc, { number_sections = true })

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
        local top_subs   = {}
        local top_n      = 0
        local top_direct = List {}
        for _, blk in ipairs(sectioned) do
          if is_section_div(blk) then
            top_n = top_n + 1
            top_subs[top_n] = blk
            top_direct:insert(pandoc.RawBlock('placeholder', tostring(top_n)))
          else
            top_direct:insert(blk)
          end
        end

        local processed_top = {}
        local top_ids = {}
        for i = 1, top_n do
          local pdiv, id_set = process(top_subs[i])
          processed_top[i] = pdiv
          for id, _ in pairs(id_set) do
            top_ids[id] = true
          end
        end

        local result = top_direct:map(function(blk)
          if blk.t == 'RawBlock' and blk.format == 'placeholder' then
            return processed_top[tonumber(blk.text)]
          end
          return blk
        end)

        doc.blocks = pandoc.Blocks(result):walk { Div = flatten_sections }
      else
        local result = process_root(sectioned, root_suffix)
        doc.blocks = pandoc.Blocks(result):walk { Div = flatten_sections }
      end

      return doc
    end
  }
}
