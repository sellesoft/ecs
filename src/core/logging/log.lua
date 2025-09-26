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
  log[verb:lower()] = function(cat, first, ...)
    if not first then
      error("log called without something to print")
    end

    local buf = require "string.buffer" .new()

    if ret then
      buf:put "__ECS_LOG_MACRO_TRUE"
    else
      buf:put "__ECS_LOG_MACRO_FALSE"
    end

    buf:put("(", cat, ',', verb, ',')

    local function recur(a, b, ...)
      buf:put(a)
      if b then
        buf:put ','
        recur(b, ...)
      end
    end

    recur(first, ...)

    buf:put ')'

    return buf:get()
  end
end

genverb("Trace", true)
genverb("Debug", true)
genverb("Info", true)
genverb("Notice", true)
genverb("Warn", true)
genverb("Error", false)
genverb("Fatal", false)

