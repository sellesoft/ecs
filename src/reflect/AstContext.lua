--- 
--- Generates and stores our internal representation of clang's AST, as well
--- as extra information about the AST as a whole.
---

local IroType = require "iro.Type"
local ast = require "reflect.ast"
local metadata = require "reflect.metadata"
local log = require "iro.Logger" ("reflect.astctx", Verbosity.Info)

---@class reflect.AstContext : iro.Type
local AstContext = IroType.make()

--- Internal helper module for converting clang's AST to our internal
--- representation.
---
---@class reflect.Converter : iro.Type
---
---@field ctx reflect.AstContext
local Converter = IroType.make()

--- Generate a new AstContext by parsing the given string. Note that the 
--- given string must form a complete translation unit, as that is all we 
--- support parsing for now.
---
---@param str string
---@return reflect.AstContext
AstContext.fromString = function(str)
  
end

Converter.convert = function(decl)
