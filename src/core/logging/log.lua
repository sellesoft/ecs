--- 
--- Module providing the actual api used to perform logging.
---
--- TODO(sushi) document the api!
---

local sbuf = require "string.buffer"

-- Logging is extremely common, so it is global.
log = {}

--- To be called as a macro, imports stuff needed to actually perform logging.
log.import = function()
  return 
  [[
#include "loggen/log_categories.h"
  ]]
end

log.chan = {}

--- IDE defs.
---@param cat string
---@param ... any
log.trace = function(cat, ...) end
---@param cat string
---@param ... any
log.debug = function(cat, ...) end
---@param cat string
---@param ... any
log.info = function(cat, ...) end
---@param cat string
---@param ... any
log.notice = function(cat, ...) end
---@param cat string
---@param ... any
log.warn = function(cat, ...) end
---@param cat string
---@param ... any
log.error = function(cat, ...) end
---@param cat string
---@param ... any
log.fatal = function(cat, ...) end

local function genverb(verb, ret)
  local function impl(is_line, chan, cat, first, ...)
    if not first then
      error("log called without something to print")
    end

    local buf = sbuf.new()

    if ret then
      buf:put "__ECS_LOG_MACRO_TRUE"
    else
      buf:put "__ECS_LOG_MACRO_FALSE"
    end

    chan = chan or "&::logging::get()->chan"

    buf:put("(", chan, ',', cat, ',', verb, ',')

    local function recur(a, b, ...)
      buf:put(a)
      if b then
        buf:put ','
        recur(b, ...)
      end
    end

    recur(first, ...)

    if is_line then
      buf:put ", '\\n'"
    end

    buf:put ')'

    return buf:get()
  end

  log[verb:lower()] = function(cat, first, ...)
    return impl(false, nil, cat, first, ...)
  end

  log[verb:lower().."ln"] = function(cat, first, ...)
    return impl(true, nil, cat, first, ...)
  end

  log.chan[verb:lower()] = function(chan, cat, first, ...)
    return impl(false, chan, cat, first, ...)
  end
end

genverb("Trace", true)
genverb("Debug", true)
genverb("Info", true)
genverb("Notice", true)
genverb("Warn", true)
genverb("Error", false)
genverb("Fatal", false)

