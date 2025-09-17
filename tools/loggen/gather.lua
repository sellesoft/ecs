--- 
--- Helper for gathering loggen definitions.
---

local def = require "core.logging.def"
local glob = require "iro.fs.glob"
local fs = require "iro.fs"
local lpp = require "lpp"

glob "src/**/*.logdef.lua" :each(function(path)
  -- Add the file as a dependency manually, since we don't run the lua file 
  -- using 'require', which is the only way lpp automatically adds dependencies
  -- on lua files atm. We could overwrite 'dofile' maybe, but not sure how I
  -- feel about patching so many lua functions atm.
  --
  -- Really, this is just cause I don't feel like transforming the path into
  -- one appropriate for 'require'. That's currently complicated by these files
  -- containing a double extension, so we'd have to adjust package.path, and 
  -- ehhhh.. this works fine for now.
  local fullpath = fs.path.canonicalize(path)
  lpp.addDependency(fullpath)

  dofile(path)
end)

return def
