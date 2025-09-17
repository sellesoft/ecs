--- 
--- Configuration important for consistenly generating and using the logging
--- infrastructure, such as how categories are named, what the headers are 
--- called and placed, etc.
---

local conf = {}

--- The header in which category globals are declared, as well as the functions
--- used to log through them.
---
--- Note that because this is a generated file, this will be placed in 
--- the build directory specified in lakefile.lua.
conf.categories_header = "loggen/categories.h"

--- Gets the name of the category global.
conf.cat_var = function(catname)
  return "cat_"..catname
end

--- Returns a string used to reference a category global.
conf.cat_ref = function(catname)
  return "::log::"..conf.cat_var(catname)
end

return conf
