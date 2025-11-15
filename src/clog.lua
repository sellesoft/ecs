---
--- Compile time logging util.
---
--- TODO(sushi) add some stuff to lpp for getting a proper call stack 
---             or at least getting the proper filename/line of the caller 
---             of a macro. We are in a post-Windows port world now and 
---             adding things to lpp/lake has become a lot more annoying
---             until I figure out a way to make it nice.
---
---@meta clog

local cmn = require "common"

local clog = {}

local verbs = 
{
  error = { color = cmn.color.red },
  warn  = { color = cmn.color.yellow },
  info  = { color = cmn.color.cyan },
  debug = { color = cmn.color.green },
}

for verb, def in pairs(verbs) do
  local buf = cmn.buffer.new()

  local function impl(a, ...)
    if a then
      buf:put(tostring(a))
      impl(...)
    end
  end

  local function actual_clog(append_line, ...)
    buf:put(def.color, verb, cmn.color.reset, ": ")
    impl(...)
    io.write(buf:get())
    if append_line then
      io.write '\n'
    end
  end

  clog[verb] = function(...)
    actual_clog(false, ...)
  end

  clog[verb.."ln"] = function(...)
    actual_clog(true, ...)
  end
end

return clog
