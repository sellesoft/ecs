--- 
--- Common stuff throughout all of ecs.
---

-- Introduce lpp as a global.
lpp = require "lpp"

os.exit = function()
  io.write("DO NOT CALL OS.EXIT\n")
  assert(false)
end

-- Introduces the log global
require "core.logging.log"

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

common.defFileLogger = function(name, verbosity)
  local buf = common.buffer.new()

  buf:put("static Logger logger = Logger::create(\"", name, 
          "\"_str, Logger::Verbosity::",verbosity,");")

  return buf:get()
end
-- Introduce as global given how common this is.
defFileLogger = common.defFileLogger

common.failIf = function(errval)
  return function(cond, ...)
      local args = common.buffer.new()
      local first = true
      for arg in common.List{...}:each() do
        if first then
          first = false
        else
          args:push ","
        end
        args:push(arg)
      end
      return [[
        if (]]..cond..[[)
        {
          ERROR(]]..args:get()..[[);
          return ]]..errval..[[;
        }]]
  end
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

return common
