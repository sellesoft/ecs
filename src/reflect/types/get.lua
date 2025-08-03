--- 
--- Simple helper function that takes an AstContext and attempts to extract
--- from it the declarations of reflect types for use in reflection code.
---

---@param astctx reflect.AstContext
return function(astctx)
  return
  {
    Array = astctx:lookupDecl "reflect::Array"
  }
end
