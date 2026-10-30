--- Sets German quotation marks for `lang: de`; Pandoc writes English ones.

local utils = require 'pandoc.utils'

local MARKS = {
  DoubleQuote = { '„', '“' },
  SingleQuote = { '‚', '‘' },
}

return {
  {
    Pandoc = function(doc)
      local lang = doc.meta.lang and utils.stringify(doc.meta.lang) or ''
      if not lang:match('^de') then return nil end
      return doc:walk {
        Quoted = function(quoted)
          local marks = MARKS[quoted.quotetype]
          local inlines = pandoc.Inlines { pandoc.Str(marks[1]) }
          inlines:extend(quoted.content)
          inlines:insert(pandoc.Str(marks[2]))
          return inlines
        end,
      }
    end,
  },
}
