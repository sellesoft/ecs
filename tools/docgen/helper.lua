local lpp = require "lpp"
local fs = require "iro.fs"

local helper = {}

helper.getArg = function(arg)
  local val
  for _,v in ipairs(lpp.argv) do
    if v:find("^%-%-"..arg.."=") then
      val = v:sub(#("--"..arg.."=") + 1)
    end
  end
  return val
end

helper.getHeader = function()
  local header
  for _,v in ipairs(lpp.argv) do
    if v:find "^%-%-header=" then
      header = v:sub(#"--header="+1)
    end
  end
  return header
end

helper.getType = function()
  local type
  for _,v in ipairs(lpp.argv) do
    if v:find "^%-%-type=" then
      type = v:sub(#"--type="+1)
    end
  end
  return type
end

helper.parseHeader = function()
  local header = helper.getHeader()
  if header:find "%.h$" then
    header = fs.path.canonicalize(header)
    return header, require "reflect.AstContext" .fromString(  
      '#include "'..header..'"')
  else
    return header, require "reflect.AstContext" .fromGlobs { header }
  end
end

return helper
