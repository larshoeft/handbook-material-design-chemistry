-- Post-render: adds the sections of every chapter (from its page TOC) to the
-- sidebar of every page, collapsed, so they can be opened on narrow screens.

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

-- Page path relative to the output dir, with forward slashes
local function key(file)
  return (path.make_relative(file, out):gsub('\\', '/'))
end

-- Resolve a sidebar href against the directory of the page it is on
local function resolve(page_key, href)
  local parts = {}
  for part in (page_key:match('^(.*)/') or ''):gmatch('[^/]+') do parts[#parts + 1] = part end
  for part in href:gsub('#.*$', ''):gmatch('[^/]+') do
    if part == '..' then
      parts[#parts] = nil
    elseif part ~= '.' then
      parts[#parts + 1] = part
    end
  end
  return table.concat(parts, '/')
end

local pages = html_files(out)
local sections = {}
for _, page in ipairs(pages) do
  local toc = read(page):match('<nav id="TOC".-</nav>')
  if toc then
    local list = {}
    for id, inner in toc:gmatch('<a href="#([^"]+)"[^>]*class="nav%-link[^"]*"[^>]*>(.-)</a>') do
      list[#list + 1] = { id = id, inner = inner }
    end
    if #list >= 2 then sections[key(page)] = list end
  end
end

for _, page in ipairs(pages) do
  local text = read(page)
  local page_key = key(page)
  local first = text:find('<nav id="quarto-sidebar"', 1, true)
  local last = first and text:find('</nav>', first, true)
  if last then
    local n = 0
    local sidebar = text:sub(first, last - 1):gsub(
      '(<a href="([^"]+)" class="sidebar%-item%-text sidebar%-link[^"]*">.-</a>)(%s*</div>)',
      function(link, href, close)
        local list = sections[resolve(page_key, href)]
        if not list then return nil end
        n = n + 1
        local id = 'sidebar-toc-' .. n
        local target = href:gsub('#.*$', '')
        local items = {}
        for _, s in ipairs(list) do
          items[#items + 1] = '<li><a href="' .. target .. '#' .. s.id .. '" class="nav-link">'
            .. s.inner .. '</a></li>'
        end
        return link
          .. '<a class="sidebar-item-toggle text-start sidebar-page-toc-toggle" data-bs-toggle="collapse"'
          .. ' data-bs-target="#' .. id .. '" role="button" aria-expanded="false" aria-label="Abschnitte">'
          .. '<i class="bi bi-chevron-right ms-2"></i></a>'
          .. close
          .. '<ul id="' .. id .. '" class="collapse list-unstyled sidebar-page-toc">'
          .. table.concat(items) .. '</ul>'
      end)
    if n > 0 then
      write(page, text:sub(1, first - 1) .. sidebar .. text:sub(last))
    end
  end
end
