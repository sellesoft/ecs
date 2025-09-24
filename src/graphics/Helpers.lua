-- 
-- Various stuff common to graphics files.
--

require "common"

local m = {}

m.defCreateErr = function(type_name, var_name)
  return function(...)
    -- TODO(sushi) this blows but we can't just '...' if we want to append 
    --             a newline. Need to make a log.errorln and such.
    local args = table.concat({...}, ',')
    return log.error("gfx", 
      '"while creating '..type_name..' \'" ', var_name, 
      ' "\': "', args, "'\\n'")
  end
end

return m
