--- 
--- Common stuff throughout all of ecs. Pretty much every file should 
--- 'require "common"' at the top. So, be careful adding things to this file 
--- as it affects the compile times of everything.
---

-- Introduce lpp as a global.
lpp = require "lpp"

-- Its usually not helpful to just exit out of lpp like this, ever. Especially
-- when running under lppls (because it will just crash the ls).
os.exit = function()
  io.write("DO NOT CALL OS.EXIT\n")
  assert(false)
end

-- Introduces the log global
require "core.logging.log"

-- Introduce global compile time log util. We do this lazily (on first use)
-- as clog.lua uses common.lua (don't feel like reorganizing it).
clog = setmetatable({}, 
{
  __index = function(_, k)
    clog = require "clog"
    return function(...)
      clog[k](...)
    end
  end
})

-- Convenience global func, usually used like '@dbgBreak;'
function dbgBreak()
  return "__builtin_debugtrap()"
end

local common = {}

common.buffer = require "string.buffer"
common.List = require "iro.List"

--- Parse the cargs that should have been provided by the lakefile.
common.cargs = common.List {}
for _,v in ipairs(lpp.argv) do
  if v:find "^%-%-cargs" then
    local cargs = v:sub(#"--cargs="+1)
    for carg in cargs:gmatch("[^,]+") do
      common.cargs:push(carg)

      -- Set -D args as globals so that we may use them in lpp as well.
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

if common.cargs:isEmpty() then
  error 
    "failed to get cargs! they should have been specified in the lakefile!"
end

-- Prevent error limit when they are thrown in reflection parsing.
common.cargs:push "-ferror-limit=0"

if ECS_CLANG_RESOURCE_DIR then
  -- Since we split third_party/bin into win32 and linux dirs now 
  -- (probably don't need to, really) we have to explicitly tell clang 
  -- where its resource dir is on linux since its default relative path 
  -- (so dumb) no longer works.
  common.cargs:push("-resource-dir="..ECS_CLANG_RESOURCE_DIR)
end

common.joinArgs = function(delim, ...)
  delim = delim or " "
  local s = ""

  local args = common.List{...}
  if args:isEmpty() then
    return 
  end

  for arg,i in args:eachWithIndex() do
    s = s..arg
    if i ~= args:len() then
      s = s..delim
    end
  end

  return s
end

-- Idk how many times I have copy pasted some enumeration of these colors 
-- in various forms throughout all of the projects I've worked on.
common.color = 
{
  black   = "\x1b[30m",
  red     = "\x1b[31m",
  green   = "\x1b[32m",
  yellow  = "\x1b[33m",
  blue    = "\x1b[34m",
  magenta = "\x1b[35m",
  cyan    = "\x1b[36m",
  white   = "\x1b[37m",
  reset   = "\x1b[0m"
}

return common
