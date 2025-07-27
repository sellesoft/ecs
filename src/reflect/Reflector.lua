-- Reflection 'system'.
local lpp = require "lpp"
local List = require "iro.List"
local buffer = require "string.buffer"

-- Load lppclang.
require "lppclang" "lib/lppclang.so"

-- Get the cargs so we can pass them to lppclang when we create the context.
local args = List{}

local nix_cflags = os.getenv("NIX_CFLAGS_COMPILE")
if nix_cflags then
  for arg in nix_cflags:gmatch("%S+") do
    args:push(arg)
  end
end

-- TODO(sushi) put this somewhere central lol this is dumb
string.startsWith = function(self, s)
  return self:sub(1, #s) == s
end

for _,v in ipairs(lpp.argv) do
  if v:startsWith "--cargs" then
    local cargs = v:sub(#"--cargs="+1)
    for carg in cargs:gmatch("[^,]+") do
      args:push(carg)
      -- Set -D defines as globals so we may use them in lpp as well.
      local define = carg:match "^%-D(.*)"
      if define then
        local name, val = define:match "(.-)=(.*)"
        if name and val then
          _G[name] = val
        end
      end
    end
  end
end

if lpp.generating_dep_file then
  lpp.registerFinal(function(result)
    if tu_name ~= lpp.getCurrentInputSourceName() then
      return
    end

    local makedeps = 
      lpp.clang.generateMakeDepFile(
        lpp.getCurrentInputSourceName(), result, args)

    -- Skip the initial obj file thing.
    makedeps = makedeps:match ".-:%s+(.*)"

    -- This is INSANELY bad but I just want to get to porting ECS to Windows
    -- so I WILL fix this later I PROMISE!
    while #makedeps ~= 0 do
      local path
      local start, stop = makedeps:find "[^\\] "
      if start then
        path = makedeps:sub(1, stop)
        makedeps = makedeps
          :sub(stop)
          :gsub("^%s+", "")
          :gsub("^\\", "")
          :gsub("^%s+", "")
      else
        path = makedeps
      end
      path = path
        :gsub("\\ ", " ")
        :gsub("\\", "/")
      lpp.addDependency(path)
      if not start then
        break
      end
    end
  end)
end

return Reflect
