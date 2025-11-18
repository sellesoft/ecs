--- 
--- Module providing information about the math lib at compile time.
---
--- At the moment this is being added to make enumerating the vector types 
--- easier, as they're no longer templated (so handling them in reflected code 
--- becomes more tedious).
---

local cmn = require "common"

local info = {}

--- Defines what vector types we want to generate in vec.lh.
info.vec_types = cmn.List {}

local function makevec(name, n, t)
  info.vec_types:push
  {
    name = name,
    len  = n,
    t    = t,
  }
end

makevec("vec2f", 2, "f32")
makevec("vec2u", 2, "u32")
makevec("vec2i", 2, "s32")

-- Not used anywhere at the moment, uncomment if we ever need these.
-- makevec("vec3f", 3, "f32")
-- makevec("vec3u", 3, "u32")
-- makevec("vec3i", 3, "s32")

makevec("vec4f", 4, "f32")
makevec("vec4u", 4, "u32")
makevec("vec4i", 4, "s32")

--- Given an AstContext, returns the Decl nodes representing each vec type.
--- Primarily for use with AstVisitor:visit.
---@param astctx reflect.AstContext
info.getVecDecls = function(astctx)
  local list = cmn.List {}
  for vt in info.vec_types:each() do
    list:push(astctx:lookupDecl(vt.name))
  end
  return list
end

return info
