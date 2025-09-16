--- 
--- Module require'd by .loggen files. Handles logic for actually gathering 
--- log stuff throughout the projects.
---

local def = require "core.logging.def"

local glob = require "iro.fs.glob"

glob "src/**/*.logdef.lua" :each(function(path)
  print(path)
end)

return def
