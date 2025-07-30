--- 
--- Generates and stores our internal representation of clang's AST, as well
--- as extra information about the AST as a whole.
---
--- TODO(sushi) we could probably handle all of this by just hooking into 
---             the actual parsing process of clang using an ASTConsumer,
---             but that is more than I would like to set up right now.
---             I had also considered setting it up so that lppclang generates
---             a lua AST for us, but that puts restrictions on how the user
---             wants the AST to actually be structured and what information
---             it wants to store. That or it complicates setting this up,
---             as we would need to define a whole api for hooking in an 
---             ASTConsumer through lppclang. This is how it is for now 
---             I guess so its easiest to get it working this way. But maybe
---             it would be more efficient to try something else later.
---

local cmn = require "common"
local IroType = require "iro.Type"
local List = require "iro.List"
local ast = require "reflect.ast"
local metadata = require "reflect.Metadata"
local log = require "iro.Logger" ("astctx", Verbosity.Trace)

---@class reflect.AstContext : iro.Type
---
--- The parsed translation unit decl.
---@field translation_unit ast.TranslationUnit
---
--- A table containing type declarations by their canonical name, as specified
--- by clang. This is primarily used for searching decls for which a collection
--- of methods are provided.
--- This table may be used directly if desired, though. However remember that 
--- lua tables are of arbitrary order!
---@field type_decls_by_canonical_name table
---
local AstContext = IroType.make()

---@return reflect.AstContext
AstContext.new = function()
  return setmetatable({}, AstContext)
end

--- Internal helper module for converting clang's AST to our internal
--- representation. Primarily for holding extra information useful for 
--- the conversion that we don't need later when actually using the resulting
--- AST.
---
---@class reflect.Converter : iro.Type
---
---@field ctx reflect.AstContext
---
---@field ns_stack iro.List
---
---@field tu ast.TranslationUnit
---
---@field processed_clang_objs table
local Converter = IroType.make()

---@return reflect.Converter
Converter.new = function()
  local o = {}
  o.ns_stack = List {}
  o.processed_clang_objs = {}
  o.depth = 0
  return setmetatable(o, Converter)
end

--- Generate a new AstContext by parsing the given string. Note that the 
--- given string must form a complete translation unit, as that is all we 
--- support parsing for now.
---
---@param str string
---@return reflect.AstContext
AstContext.fromString = function(str)
  local Context = require "lppclang" "lib/lppclang.so"

  local ctx = Context.new(cmn.cargs)
  local Converter = Converter.new()

  local astctx = AstContext.new()

  astctx.translation_unit =
    Converter:processTranslationUnit(ctx:parseString(str))
      or error "failed to convert clang ast"

  return astctx
end

Converter.findProcessed = function(self, cdecl)
  return self.processed_clang_objs[tostring(cdecl.handle)]
end 

Converter.recordProcessed = function(self, cdecl, obj)
  self.processed_clang_objs[tostring(cdecl.handle)] = obj
end

Converter.write = function(self, ...)
  for i = 1,self.depth do
    log:debug " "
  end

  log:debug(...)
  log:debug "\n"
end

---@class convwrap : reflect.Converter
local convfunc = setmetatable({}, 
{
  __newindex = function(_, k, f)
    lpp.stacktrace_func_rename[f] = k
    Converter[k] = function(self, ...)
      self:write(k, ":")
      self.depth = self.depth + 1
      local function inpassing(...)
        self.depth = self.depth - 1
        return ...
      end
      return inpassing(f(self, ...))
    end
    lpp.stacktrace_func_filter[Converter[k]] = true
  end
})

---@param tu lppclang.Decl
---@return ast.TranslationUnit
convfunc.processTranslationUnit = function(self, tu)
  self.tu = ast.TranslationUnit.new()

  -- tu:dump()

  local iter = tu:getContextIter()
  local cdecl = iter:next()
  while cdecl do
    local decl =
      self:processTranslationUnitDecl(cdecl) 

    if decl then
      self.tu.decls:push(decl)
    end

    cdecl = iter:next()
  end

  return self.tu
end

---@param cdecl lppclang.Decl
---@return ast.Decl?
convfunc.processTranslationUnitDecl = function(self, cdecl)
  -- Weird case, not sure why this happens.
  if cdecl:getName() == "" then
    return 
  end

  -- We don't process top-level template specializations. Don't remember why.
  -- It just caused some issues for some reason.
  if cdecl:isTemplateSpec() then
    return
  end

  if cdecl:isNamespace() then
    return (self:processNamespaceDecl(cdecl))
  else
    return (self:resolveDecl(cdecl))
  end
end

---@param cdecl lppclang.Decl
---@return ast.Namespace?
convfunc.processNamespaceDecl = function(self, cns)
  local name = cns:getName()

  if name == "std" then
    -- Ignore converting std stuff, cause its a mess, bloated, dumb, stupid,
    -- and we don't use it in our projects. 
    return
  end

  self:write("name: ", name)

  local ns = ast.Namespace.new(name, self.ns_stack:last())
  self.ns_stack:push(ns)

  local iter = cns:getContextIter()
  local cdecl = iter:next()
  while cdecl do

    local decl
    if cdecl:isNamespace() then
      decl = self:processNamespaceDecl(cdecl)      
    else
      decl = self:resolveDecl(cdecl)
    end

    if decl then
      ns.decls:push(decl)
    end

    cdecl = iter:next()
  end

  self.ns_stack:pop()
  return ns
end

---@return lppclang.Decl
Converter.ensureDefinitionDecl = function(self, cdecl)
  if cdecl:isTag() then
    return cdecl:getDefinition() or cdecl
  end
  return cdecl
end

--- Resolves an lppclang decl to an internal ast.Decl. If we've already 
--- converted the given decl, it is returned, otherwise it is fully converted.
---@param cdecl lppclang.Decl
---@return ast.Decl?
convfunc.resolveDecl = function(self, cdecl, resolving_forward)
  self:write("name: ", cdecl:getName())

  -- Check if we've already processed this decl and return it if so.
  local processed = self:findProcessed(cdecl)
  if processed then
    self:write("already processed")
    return processed
  end

  if not resolving_forward then
    if cdecl:isRecord() and not cdecl:isComplete() then
      self:write("forward record")
      local complete_decl = self:resolveDecl(cdecl, true)
      local forward = ast.ForwardRecord.new(cdecl:getName(), complete_decl)
      self:recordProcessed(cdecl, forward)
      return forward
    end
  else
    self:write("resolving forward declaration")

    -- Ensure that we have the actual definition of this cdecl.
    cdecl = self:ensureDefinitionDecl(cdecl)

    if cdecl:isRecord() and not cdecl:isComplete() then
      -- If we still don't have a complete definition of this record, then
      -- it must not exist in this translation unit, so don't do anything with
      -- it and allow the forward record to contain a nil decl to indicate 
      -- this.
      self:write("must not be declared in this tu")
      return
    end

    -- Check again for if we have already processed the definition decl
    -- to prevent multiple forward declarations of the same type from 
    -- generating multiple ast.Records. If we do that, we cannot properly 
    -- compare the tables to check in reflection code if we've already 
    -- generated something based on a forward declared record.
    local processed = self:findProcessed(cdecl)
    if processed then
      self:write("already processed")
      return processed
    end
  end

  -- We don't deal with template declarations for now.
  if cdecl:isTemplate() then return end

  -- We should only be getting type declarations in here for now.
  if not cdecl:isType() then
    self:write("not type decl")
    return
  end

  local ctype = cdecl:getTypeDeclType()

  ---@type ast.Decl
  local decl

  if cdecl:isTemplateSpec() then
    decl = self:processTemplateSpec(cdecl, ctype)
  elseif cdecl:isStruct() then
    decl = self:processStruct(cdecl, ctype)
  elseif cdecl:isUnion() then
    decl = self:processUnion(cdecl, ctype)
  elseif cdecl:isEnum() then
    decl = self:processEnum(cdecl, ctype)
  elseif cdecl:isTypedef() then
    decl = self:processTypedef(cdecl, ctype)
  else
    cdecl:dump()
    error "unhandled decl kind"
  end

  if decl then
    decl.type = self:resolveType(ctype)
    decl.comment = cdecl:getComment()
    if decl:is(ast.Record) and cdecl:isAnonymous() then
      decl.is_anonymous = true
    end
    self:write('>>> ', decl)
  end

  return decl
end

--- Similar to resolveDecl, but for Types.
---@param ctype lppclang.Type
---@return ast.Type
convfunc.resolveType = function(self, ctype)
  local type

  -- Grab the name ONCE, because lppclang internally has to allocate memory
  -- for the typename.
  local name = ctype:getName()

  self:write("name: ", name)

  if ctype:isPointer() then
    if ctype:isFunctionPointer() then
      self:write("is function pointer")
      type = ast.FunctionPointer.new()
      type.size = ctype:getSize() / 8
    else
      self:write("> is pointer")
      local subctype = ctype:getPointeeType()
        or error("failed to get subtype of pointer")
      self:write("> subtype: ", subctype:getName())
      local subtype = self:resolveType(subctype)
      type = ast.Pointer.new(subtype)
      type.size = ctype:getSize() / 8
    end
  elseif ctype:isReference() then
    self:write("> is reference")
    local subctype = ctype:getPointeeType()
      or error("failed to get subtype of reference")
    self:write("> subtype: ", subctype:getName())
    local subtype = self:resolveType(subctype)
    type = ast.Reference.new(subtype)
    type.size = ctype:getSize() / 8
  elseif ctype:isArray() then
    self:write("is array")
    local subctype = ctype:getArrayElementType()
      or error("failed to get subtype of array")
    local subtype = self:resolveType(subctype)
    local len = ctype:getArrayLen()
    type = ast.CArray.new(subtype, len)
    type.size = ctype:getSize() / 8
  elseif ctype:isElaborated() then
    -- Check if this is one of iro's typedefs of builtin types and return 
    -- our internal representation of it. This is a little cheat to get around
    -- having to unwrap them in reflection code. Cause that's really annoying.
    -- And y'know, we use these literally everywhere,
    if ast.builtins[name] then
      return ast.builtins[name]
    end

    self:write("is elaborated")
    local desugared = ctype:getSingleStepDesugared()
      or error("failed to get desugared type")
    type =
      ast.Elaborated.new(name, self:resolveType(desugared))
    type.size = type.subtype.size
  elseif ctype:isBuiltin() then
    self:write("is builtin")
    type = ast.Builtin.new(name, ctype:getSize() / 8)
  elseif ctype:isTypedef() then

    self:write("is typedef")
    local decl = self:resolveDecl(ctype:getTypedefDecl())
    if not decl then
      ctype:dump()
      error("failed to get typedef decl")
    end
    type = ast.TypedefType.new(decl)
    if decl:is(ast.TypedefDecl) then
      type.size = decl.subtype.size
    else
      type.size = ctype:getSize() / 8
    end
  else
    local canonical_ctype = ctype:getCanonicalType()
    if canonical_ctype then
      if canonical_ctype:isBuiltin() then
        local builtin = ast.BuiltinType[canonical_ctype:getName()]
        if not builtin then
          canonical_ctype:dump()
          error("failed to get builtin type")
        end
        return builtin
      end
    end

    local cdecl = ctype:getDecl()

    if not cdecl then
      ctype:dump()
      error("failed to get type decl")
    end

    local decl = self:resolveDecl(cdecl)
    if not decl then
      error("unable to resolve decl of type '"..ctype:getName().."'")
    end

    if decl:is(ast.TagDecl) or decl:is(ast.ForwardRecord) then
      type = ast.TagType.new(decl)
      if cdecl:isComplete() then
        type.size = ctype:getSize() / 8
      end
    elseif decl:is(ast.TypedefDecl) then
      type = ast.TypedefType.new(decl)
      if cdecl:isComplete() then
        type.size = ctype:size() / 8
      end
    else
      ctype:dump()
      error("unhandled type")
    end
  end

  return type
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
---@return ast.Struct
convfunc.processStruct = function(self, cdecl, ctype)
  local struct = ast.Struct.new(ctype:getCanonicalType():getName())
  self:recordProcessed(cdecl, struct)

  self:processRecordMembers(cdecl, ctype, struct)

  if cdecl:isComplete() then
    self:collectBaseAndDerived(cdecl, struct)

    struct.comment = cdecl:getComment()
    if struct.comment then
      struct.metadata = metadata.__parse(struct.comment)
    end

    struct.is_complete = true
  end

  return struct
end

---@param cdecl lppclang.Decl
---@param record ast.Record
convfunc.collectBaseAndDerived = function(self, cdecl, record)
  local baseiter = cdecl:getBaseIter()
  local base = baseiter:next()
  while base do
    if record.base then
      log:warn("record '", record.name, "' has multiple bases, but ecs does ",
               "not support multiple inheritance in its reflection system")
      break
    end

    local basedecl = base:getDecl()
    if basedecl then
      ---@type ast.Record
      local decl = self:resolveDecl(basedecl) or 
        error("failed to resolve decl for base")
      if decl then
        decl.derived:push(record)
        record.base = decl
      end
    end

    base = baseiter:next()
  end
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
---@return ast.Union
convfunc.processUnion = function(self, cdecl, ctype)
  local union = ast.Union.new(ctype:getCanonicalType():getName())
  self:recordProcessed(cdecl, union)

  self:processRecordMembers(cdecl, ctype, union)

  return union
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
---@return ast.TemplateSpec
convfunc.processTemplateSpec = function(self, cdecl, ctype)
  local specdecl = cdecl:getSpecializedDecl()
    or error("failed to get specialized decl of template specialization")

  local spec = 
    ast.TemplateSpec.new(
      ctype:getCanonicalType():getName(),
      specdecl:getName())

  self:recordProcessed(cdecl, spec)

  local args = cdecl:getTemplateArgIter()
  local arg = args:next()
  while arg do
    if arg:isType() then
      spec.args:push(self:resolveType(assert(arg:getType())))
    elseif arg:isIntegral() then
      spec.args:push(arg:getIntegral())
    else
      spec.has_unhandled_arg_kind = true
      log:warn("unhandled template arg kind in ", spec.name, "\n")
    end

    arg = args:next()
  end

  if cdecl:isComplete() then
    self:collectBaseAndDerived(cdecl, spec)

    spec.comment = cdecl:getComment()
    if spec.comment then
      spec.metadata = metadata.__parse(spec.comment)
    end

    spec.is_complete = true
  end

  self:processRecordMembers(cdecl, ctype, spec)

  return spec
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
convfunc.processRecordMembers = function(self, cdecl, ctype, record)
  local memiter = cdecl:getContextIter()

  self:write("members of ", cdecl:getName())

  local cmember = memiter:next()
  while cmember do
    if cmember:isField() then
      local field_ctype = cmember:getType()
      assert(field_ctype, "failed to get lppclang.Type of field")
      local field_type = self:resolveType(field_ctype)

      -- Resolve the actual underlying type of the field, eg. with sugar 
      -- removed.
      local type = field_type
      while true do
        if type:is(ast.Elaborated) then
          type = type.subtype
        elseif type:is(ast.TagType) then
          break
        else
          break
        end
      end

      local field =
        ast.Field.new(
          cmember:getName(),
          field_type,
          cmember:getFieldOffset() / 8)

      field.comment = cmember:getComment()
      if field.comment then
        field.metadata = metadata.__parse(field.comment)
      end

      self:write("!! add member ", field.name)

      record:addMember(field.name, field)
    elseif cmember:isTag() then
      local member_decl = self:resolveDecl(cmember)
      assert(member_decl, "failed to resolve record member decl")
      member_decl.parent = record
      record:addMember(member_decl.name, member_decl)
    elseif cmember:isFunction() then
      local name = cmember:getName()
      record:addMember(name, ast.Function.new(name))
    end

    cmember = memiter:next()
  end
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
---@return ast.Enum
convfunc.processEnum = function(self, cdecl, ctype)
  local enum = ast.Enum.new(ctype:getCanonicalType():getName())
  self:recordProcessed(cdecl, enum)

  local iter = cdecl:getEnumIter()
  local elem = iter:next()
  while elem do
    local e = {}
    e.name = elem:getName()
    e.comment = elem:getComment()
    if e.comment then
      e.metadata = metadata.__parse(e.comment)
    else
      e.metadata = {}
    end
    e.value = elem:getEnumValue()
    enum.elems:push(e)
    elem = iter:next()
  end

  return enum
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
---@return ast.TypedefDecl
convfunc.processTypedef = function(self, cdecl, ctype)
  local typedef = ast.TypedefDecl.new(ctype:getName())
  self:recordProcessed(cdecl, typedef)

  typedef.subtype = self:resolveType(assert(cdecl:getTypedefSubType()))
    or error("failed to get subtype of typedef "..ctype:getName())

  typedef.comment = cdecl:getComment()
  if typedef.comment then
    typedef.metadata = metadata.__parse(typedef.comment)
  end

  return typedef
end

return AstContext
