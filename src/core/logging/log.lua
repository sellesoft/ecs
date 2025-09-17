--- 
--- Module providing the actual api used to perform logging.
---
--- TODO(sushi) document the api!
---

-- Logging is extremely common, so it is global.
log = {}

--- To be called as a macro, imports stuff needed to actually perform logging.
log.import = function()
  return 
  [[
#include "loggen/log_categories.h"
  ]]
end

local function genverb(verb)
  log[verb:lower()] = function(cat, ...)
    local buf = require "string.buffer" .new()

    buf:put("::log::through_cat_", cat, "(::log::Verbosity::", verb, ',')

    local function recur(a, b, ...)
      buf:put(a)
      if b then
        buf:put ','
        recur(b, ...)
      end
    end

    recur(...)

    buf:put ')'

    return buf:get()
  end
end

genverb "Trace"
genverb "Debug"
genverb "Info"
genverb "Notice"
genverb "Warn"
genverb "Error"
genverb "Fatal"

