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
--- TODO(sushi) move the conversion stuff out to its own file as this should 
---             just contain the api for AstContext.
---

local cmn = require "common"
local IroType = require "iro.Type"
local List = require "iro.List"
local ast = require "reflect.ast"
local metadata = require "reflect.Metadata"
local glob = require "iro.fs.glob"

local debug_print = false

---@class reflect.AstContext : iro.Type
---
--- The parsed translation unit decl.
---@field translation_unit ast.TranslationUnit
---
--- A table containing declarations by their qualified name, eg. 
---   namespace iro 
---   {
---   namespace utf8
---   {
---     struct String {};
---   }
---   }
--- has the qualified name "iro::utf8::String". This works similarly for nested
--- enums and structs and such.
---@field decls_by_qualified_name table
---
--- A table containing type declarations keyed by their name. This is where
--- more complicated types such as vec2<int> or iro::Array<iro::String> may
--- be found.
---@field type_decls_by_name table
---
--- A list of type declarations for iterating in proper order.
---@field type_decls iro.List
---
local AstContext = IroType.make()

---@return reflect.AstContext
AstContext.new = function()
  local o = {}
  o.type_decls = List {}
  o.decls_by_qualified_name = {}
  o.type_decls_by_name = {}
  
  return setmetatable(o, AstContext)
end

--- Looks up a declaration by its fully qualified name, as described in 
--- the comment on AstContext.decls_by_qualified_name.
---
---@return ast.Decl?
AstContext.lookupDecl = function(self, name)
  -- TODO(sushi) this could be made more fancy, eg. handling whitespace 
  --             independent tokens 
  --               like:
  --                 iro :: ut8::String 
  --                successfully returning the decl of String.
  --              and stuff like searching with non-canonical names like just 
  --              'String' also successfully returning. Don't want to get too
  --              bogged down in that atm, though.
  --              And its probably safer to require canonical names for now.
  return self.decls_by_qualified_name[name]
end

--- Looks up a type declaration by its canonical typename.
---
---@return ast.TypeDecl?
AstContext.lookupTypeDecl = function(self, name)
  return self.type_decls_by_name[name]
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
Converter.new = function(astctx)
  local o = {}
  o.ns_stack = List {}
  o.processed_clang_objs = {}
  o.depth = 0
  o.ctx = astctx
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

  local astctx = AstContext.new()
  local Converter = Converter.new(astctx)

  astctx.translation_unit =
    Converter:processTranslationUnit(ctx:parseString(str))
      or error "failed to convert clang ast"

  return astctx
end

--- Generate a new AstContext from a list of import glob patterns.
---
---@param patterns table | iro.List
---@return reflect.AstContext, string
AstContext.fromGlobs = function(patterns)
  local imported = cmn.buffer.new()

  for pattern in List(patterns):each() do
    glob(pattern):each(function(path)
      local result = lpp.import(path)

      if result then
        imported:put(result:get())
      end
    end)
  end

  return AstContext.fromString(tostring(imported)), imported
end

Converter.findProcessed = function(self, cdecl)
  return self.processed_clang_objs[tostring(cdecl.handle)]
end 

Converter.recordProcessed = function(self, cdecl, obj)
  -- io.write("record processed_", obj.name, " ", tostring(cdecl.handle), '\n')
  -- if obj.name == "String" then
  --   cdecl:dump()
  -- end
  self.processed_clang_objs[tostring(cdecl.handle)] = obj
end

Converter.write = function(self, ...)
  if debug_print then
    for i = 1,self.depth do
      io.write " "
    end

    local function recur(a, ...)
      if a then
        io.write(tostring(a))
        recur(...)
      end
    end
    recur(...)

    io.write "\n"
  end
end

---@class convwrap : reflect.Converter
local convfunc = setmetatable({}, 
{
  __newindex = function(_, k, f)
    lpp.stack_func_rename[f] = k
    Converter[k] = function(self, ...)
      self:write(k, ":")
      self.depth = self.depth + 1
      local function inpassing(...)
        self.depth = self.depth - 1
        return ...
      end
      return inpassing(f(self, ...))
    end
    lpp.stack_func_filter[Converter[k]] = true
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

--- Helper for properly checking if a decl is complete. This handles 
--- cases where a complete definition is not required, such as for 
--- template specializations.
---
---@param decl lppclang.Decl
---@return boolean
local function isCompleteDecl(decl)
  if decl:isTag() then
    if decl:isTemplateSpec() then
      -- NOTE(sushi) clang does not require template specializations to have 
      --             a complete definition, which I believe makes sense, since
      --             they can instantiated as types and such. So we just 
      --             return true in that case to avoid them being marked 
      --             as incomplete ForwardRecords.
      return true
    else
      return decl:isComplete()
    end
  end
  return true
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
    if cdecl:isRecord() and not isCompleteDecl(cdecl) then
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

  local ctype
  if cdecl:isType() then
    ctype = cdecl:getTypeDeclType()
    ctype:makeComplete()
  end

  ---@type ast.Decl
  local decl

  if cdecl:isTemplate() then
    decl = self:processTemplate(cdecl)
  elseif cdecl:isTemplateSpec() then
    -- Ensure the the declaration this specializes is resolved. Its somehow
    -- possible that we come across a specialization of a template before its
    -- actual declaration. I'm not sure how, but it happens, and I don't feel
    -- like looking into how atm.
    self:resolveDecl(cdecl:getSpecializedDecl())
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
    -- cdecl:dump()
  end

  if decl then
    -- Gather a bunch of other information about the decl that is easier to
    -- handle here than in the process functions. Really, I should set up
    -- those functions to cascade down the class hierarchy of clang such that
    -- this stuff is set more appropriately.

    decl.comment = cdecl:getComment()
    if decl:is(ast.TagDecl) and cdecl:isAnonymous() then
      decl.is_anonymous = true
    end
    decl.namespace = self.ns_stack:last()

    --- TODO(sushi) document this if it winds up not causing issues. This 
    ---             just allows every decl to have some sort of user data
    ---             associated with it, since that's a much easier solution
    ---             than the stuff I used to do in reflection code.
    decl.user = {}
    decl.cdecl = cdecl
    decl.qname = cdecl:getQualifiedName()
    
    if not decl:is(ast.TemplateSpec) then
      -- Only record the decl if its not a template specialization, because 
      -- the qualified name of a template spec is the same as its original
      -- declaration, which causes the stored decl to be overwritten by 
      -- whatever the last specialization of it we processed was.
      self.ctx.decls_by_qualified_name[decl.qname] = decl
    else
      local specialized = self.ctx:lookupDecl(decl.qname)
      if not specialized then
        io.write("error: ---- template not defined ", decl.qname, '\n')
      end

      -- In the case that this is a template spec, set what declaration
      -- it specializes.
      decl.specialized = specialized
    end

    if decl:is(ast.TypeDecl) then
      decl.type = self:resolveType(ctype)
      self.ctx.type_decls:push(decl)
      self.ctx.type_decls_by_name[decl.type.name] = decl
    end

    self:write(decl.qname)
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
  -- TODO(sushi) actually like, abide by this. I'm too lazy to do so right now
  --             and it doesn't seem like a HUGE issue.
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

    type.subtype.elaborations = type.subtype.elaborations or List {}
    type.subtype.elaborations:push(type)
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
        local builtin = ast.builtins[canonical_ctype:getName()]
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

  if type then
    type.name = ctype:getName()
  end

  return type
end

---@param cdecl lppclang.Decl
---@return ast.Template?
convfunc.processTemplate = function(self, cdecl)
  local template = ast.Template.new(cdecl:getName())
  self:recordProcessed(cdecl, template)

  template.comment = cdecl:getComment()
  if template.comment then
    template.metadata = metadata.__parse(template.comment)
  end

  return template
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
---@return ast.Struct
convfunc.processStruct = function(self, cdecl, ctype)
  local struct = ast.Struct.new(cdecl:getName())
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
      -- TODO(sushi) this should be an error in the packing/compiling/linking
      --             tools, this warning is mostly just annoying.
      io.write("warn: record '", record.name, 
               "' has multiple bases, but ecs does ",
               "not support multiple inheritance in its reflection system\n")
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
  local union = ast.Union.new(cdecl:getName())
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
      cdecl:getName(),
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
      io.write("warn: unhandled template arg kind in ", spec.name, "\n")
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

  local last_field 
  local cmember = memiter:next()
  while cmember do
    if cmember:isField() then
      local field_ctype = cmember:getType()
      assert(field_ctype, "failed to get lppclang.Type of field")
      local field_type = self:resolveType(field_ctype)

      -- Resolve the actual underlying type of the field, eg. with sugar 
      -- removed.
      -- TODO(sushi) we may not want to do this here, the elaboration might
      --             be nice.
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
      
      if not last_field then
        field.is_first = true
      end
      last_field = field
    elseif cmember:isTag() then
      -- Ensure that the type that this sub tag record declares is complete.
      -- This is done to get around cases where the record is only ever 
      -- referred to as a pointer, eg. StringMap<T>::Slot. Clang will not 
      -- complete those types until they are actually used, or something.
      -- Its difficult to explain as I am KINDA BURNT OUT after trying to 
      -- figure out the best place to do this with how things are organized 
      -- now!!!
      local member_typedecl = cmember:getTypeDeclType()
      member_typedecl:makeComplete()

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

  if last_field then
    last_field.is_last = true
  end
end

---@param cdecl lppclang.Decl
---@param ctype lppclang.Type
---@return ast.Enum
convfunc.processEnum = function(self, cdecl, ctype)
  local enum = ast.Enum.new(cdecl:getName())
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
  local typedef = ast.TypedefDecl.new(cdecl:getName())
  self:recordProcessed(cdecl, typedef)

  typedef.subtype = self:resolveType(assert(cdecl:getTypedefSubType()))
    or error("failed to get subtype of typedef "..ctype:getName())

  typedef.comment = cdecl:getComment()
  if typedef.comment then
    typedef.metadata = metadata.__parse(typedef.comment)
  end

  local desugared = typedef.subtype:desugar()
  if desugared:is(ast.TagType) then
    local subdecl = desugared.decl
    -- TODO(sushi) document
    subdecl.typedefs = subdecl.typedefs or List {}
    subdecl.typedefs:push(typedef)
  end

  return typedef
end

return AstContext
