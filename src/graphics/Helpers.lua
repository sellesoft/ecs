-- 
-- Various stuff common to graphics files.
--

require "common"

local m = {}

m.defCreateErr = function(type_name, var_name)
  return function(...)
    return log.error("gfx", 
      '"while creating '..type_name..' \'" ', var_name, 
      ' "\': "', ..., "'\\n'")
  end
end

return m
