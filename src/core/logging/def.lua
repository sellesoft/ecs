--- 
--- Module used to gather information about logging stuff around the project 
--- in the loggen build step.
---
--- TODO(sushi) document this, its very important.
---
---@meta core.logging.def

--- TODO(sushi) some kind of assert preventing this from being require'd 
---             outside of the loggen build step.

local List = require "iro.List"

local def = {}

local categories_map = {}
local categories_list = List {}

--- Creates a new Category.
def.category = function(name, opts)
  local existing = categories_map[name]
  if existing then
    error("category '"..name.."' already defined at "..
          existing.sloc.filename..":"..existing.sloc.line, 2)
  end

  local cat = {}
  cat.name = name

  local info = debug.getinfo(2, "Sl")
  cat.sloc = 
  {
    filename = info.short_src,
    line = info.currentline,
  }

  cat.opts = opts or {}

  categories_map[name] = cat
  categories_list:push(cat)

  return cat
end

--- Internal function for getting the category map/list once we are ready to
--- generate stuff.
def._get_categories = function()
  return { map = categories_map, list = categories_list }
end

return def
