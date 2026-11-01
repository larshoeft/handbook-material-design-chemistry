-- Post-render: numbers floats per ## section (4.6.1) instead of per chapter (4.3).
-- Quarto resolves float numbers only after all filters, so this edits the output.

local system, path = pandoc.system, pandoc.path
local out = os.getenv('QUARTO_PROJECT_OUTPUT_DIR') or '_book'

local function read(file)
  local f = assert(io.open(file, 'rb'))
  local text = f:read('a')
  f:close()
  return text
end

local function write(file, text)
  local f = assert(io.open(file, 'wb'))
  f:write(text)
  f:close()
end

local function html_files(dir, files)
  files = files or {}
  for _, name in ipairs(system.list_directory(dir)) do
    local full = path.join({ dir, name })
    if name:match('%.html$') then
      files[#files + 1] = full
    elseif not name:match('%.') and pcall(system.list_directory, full) then
      html_files(full, files)
    end
  end
  return files
end

local function escape(text)
  return (text:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'))
end

-- Tokens in document order: section number, float id, float caption
local function tokens(text)
  local list = {}
  for pos, sec in text:gmatch('()<h2 data%-number="([%d%.]+)"') do
    list[#list + 1] = { pos = pos, sec = sec }
  end
  for pos, kind in text:gmatch('()<div id="(%a+)%-[^"]*" class="quarto%-float') do
    list[#list + 1] = { pos = pos, kind = kind }
  end
  for pos, label, num in text:gmatch('()<figcaption[^>]*>%s*([^&<%s]+)&nbsp;(%d[%d%.]*%d):') do
    list[#list + 1] = { pos = pos, label = label, num = num }
  end
  table.sort(list, function(a, b) return a.pos < b.pos end)
  return list
end

local pages = html_files(out)
local mapping, labels = {}, {}
for _, page in ipairs(pages) do
  local sec, counts, kind = nil, {}, nil
  for _, t in ipairs(tokens(read(page))) do
    if t.sec then
      sec, counts = t.sec, {}
    elseif t.kind then
      kind = t.kind
    elseif kind and sec and t.label and t.num:find('.', 1, true) then
      counts[kind] = (counts[kind] or 0) + 1
      mapping[t.label .. '\0' .. t.num] = sec .. '.' .. counts[kind]
      labels[t.label] = true
      kind = nil
    end
  end
end

local SEPARATORS = { '&nbsp;<span>', '&nbsp;', '\194\160', ' ' }

local function renumber(text)
  for label in pairs(labels) do
    for _, sep in ipairs(SEPARATORS) do
      text = text:gsub(escape(label .. sep) .. '(%d[%d%.]*%d)', function(num)
        local new = mapping[label .. '\0' .. num]
        return new and (label .. sep .. new) or nil
      end)
    end
  end
  return text
end

local search = path.join({ out, 'search.json' })
local files = pages
if pcall(read, search) then files[#files + 1] = search end
for _, file in ipairs(files) do
  local text = read(file)
  local new = renumber(text)
  if new ~= text and (not file:match('%.json$') or pcall(pandoc.json.decode, new)) then
    write(file, new)
  end
end
