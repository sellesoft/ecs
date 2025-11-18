--- 
--- Attempt at cleaning up the AST walking that several files are currently
--- doing.
---
--- This isn't *really* an AST visitor in the sense that it will call a 
--- visitor for every single node, I just don't have a better name. 
---
--- TODO(sushi) explain this once my head stops hurting.
---
---@meta reflect.AstVisitor

local cmn = require "common"

local IroType = require "iro.Type"
local List = require "iro.List"
local ast = require "reflect.ast"

-- * --------------------------------------------------------------------------

---@class reflect.AstVisitor : iro.Type
---@field astctx reflect.AstContext
---@field pre table
---@field post table
---@field record_stack iro.List
local AstVisitor = IroType.make()

---@class reflect.AstVisitor.Opts
---
---

local stop = {}
local handled = {}

-- Internal value signalling that some node was not handled by a visitor.
-- Used to tell if we should try a visitor for a more abstract node kind,
-- eg. handleStruct returns unhandled, so handleRecord tries to call a 
-- Record visitor instead.
local unhandled = {}

--- Indicates that you want to stop walking the tree entirely.
AstVisitor.stop = stop

--- Indicates that you've handled some node and AstVisitor should not 
--- recurse any further.
AstVisitor.handled = handled

-- * --------------------------------------------------------------------------

AstVisitor.new = function(astctx)
  local o = {}
  o.pre = 
  {
    type = {},
    decl = {},
    spec = {},
  }
  o.post = 
  {
    type = {},
    decl = {},
    spec = {},
  }
  o.record_stack = List {}
  o.visited = List {}
  o.astctx = astctx
  return setmetatable(o, AstVisitor)
end

-- * --------------------------------------------------------------------------

local function addVisitor(self, cat, name, spec, f)
  if List:isTypeOf(spec) then
    for s in spec:each() do
      addVisitor(self, cat, name, s, f)
    end
    return
  end

  local function checkExists(tbl)
    if tbl[spec] then
      error("a "..name.." has already been specified for "..spec.node_name)
    end
  end

  if spec:is(ast.Template) then
    checkExists(cat.spec)
    cat.spec[spec] = f
  elseif spec:is(ast.Decl) then
    checkExists(cat.decl)
    cat.decl[spec] = f
  elseif spec:is(ast.Type) then
    checkExists(cat.type)
    cat.type[spec] = f
  else
    clog.errorln("unhandled spec ", spec.node_name)
  end
end

-- * --------------------------------------------------------------------------

AstVisitor.visit = function(self, spec, f)
  if not spec then
    error("AstVisitor.visit passed a nil spec")
  end 
  
  addVisitor(self, self.post, "visitor", spec, f)
end

-- * --------------------------------------------------------------------------

AstVisitor.previsit = function(self, spec, f)
  if not spec then
    error("AstVisitor.previsit passed a nil spec")
  end 

  addVisitor(self, self.pre, "previsitor", spec, f)
end

-- * --------------------------------------------------------------------------

local function tryVisitors(self, tbl, node, spec, ...)
  local function getVisitor(x)
    if x:is(ast.Template) then
      return tbl.spec[x]
    elseif x:is(ast.Decl) then
      return tbl.decl[x]
    elseif x:is(ast.Type) then
      return tbl.type[x]
    else
      assert(false, "unhandled cat for "..tostring(x))
    end
  end

  -- Try the node first.
  -- TODO(sushi) kinda sucks that we are trying the node several times with
  --             how this function is used but whatever.
  local node_visiter = getVisitor(node)
  if node_visiter then
    return node_visiter(node)
  end

  local function eachSpec(spec, ...)
    if spec then
      local visitor = getVisitor(spec)
      if visitor then
        return visitor(node)
      end
      return eachSpec(...)
    end
    return unhandled
  end

  return eachSpec(spec, ...)
end

-- * --------------------------------------------------------------------------

AstVisitor.handleType = function(self, type)
  type.astv = type.astv or {}

  if type.astv.visited then
    return
  end

  type.astv.visited = true

  local result = unhandled
    
  result = tryVisitors(self,
    self.pre, 
    type, 
    ast.Pointer,
    ast.Type)

  if result == handled then
    return
  elseif result == stop then
    return stop
  end

  if type:is(ast.TagType) then
    result = self:handleDecl(type.decl)
  elseif type:is(ast.TypedefType) then
    result = self:handleDecl(type.decl)
  elseif type:is(ast.CArray) then
    result = self:handleType(type.subtype)
  end

  if result == unhandled and not type.astv.visited then
    result = tryVisitors(self,
      self.post, 
      type, 
      ast.Pointer,
      ast.Type)

    if result == handled then
      return
    elseif result == stop then
      return stop
    end
  end

  return result
end

-- * --------------------------------------------------------------------------

---@param decl ast.TemplateSpec
AstVisitor.handleTemplateSpec = function(self, decl)
  for arg in decl.args:each() do
    if type(arg) == "table" and arg:is(ast.Type) then
      if stop == self:handleType(arg) then
        return stop
      end
    end
  end

  return tryVisitors(self,
    self.post,
    decl,
    decl.specialized,
    ast.TemplateSpec)
end

-- * --------------------------------------------------------------------------

AstVisitor.handleStruct = function(self, decl)
  for field in decl:eachField() do
    if stop == self:handleType(field.type) then
      return stop
    end
  end

  return tryVisitors(self,
    self.post,
    decl,
    ast.Struct)
end

-- * --------------------------------------------------------------------------

AstVisitor.handleRecord = function(self, decl)
  self.record_stack:push(decl)

  local result = tryVisitors(self, self.pre, decl, ast.Record)
  if result == handled then
    return
  elseif result == stop then
    return stop
  end

  if decl:is(ast.TemplateSpec) then
    result = self:handleTemplateSpec(decl)
  elseif decl:is(ast.Struct) then
    result = self:handleStruct(decl)
  end

  if result == unhandled then
    result = tryVisitors(self, self.post, decl, ast.Record)
  end

  self.record_stack:pop()

  return result
end

-- * --------------------------------------------------------------------------

AstVisitor.handleEnum = function(self, decl)
  return tryVisitors(self, 
    self.post,
    decl,
    ast.Enum)
end

-- * --------------------------------------------------------------------------

AstVisitor.handleTypedefDecl = function(self, decl)
  if stop == self:handleType(decl.subtype) then
    return stop
  end

  return tryVisitors(self,
    self.post, 
    decl, 
    ast.TypedefDecl)
end

-- * --------------------------------------------------------------------------

AstVisitor.handleDecl = function(self, decl)
  decl.astv = decl.astv or {}
  if decl.astv.visited then
    return
  end

  decl.astv.visited = true

  local result
  if decl:is(ast.TagDecl) then
    if decl:is(ast.Record) then
      result = self:handleRecord(decl)
    elseif decl:is(ast.Enum) then
      result = self:handleEnum(decl)
    end
  elseif decl:is(ast.TypedefDecl) then
    result = self:handleTypedefDecl(decl)
  else
    -- clog.warnln("unhandled decl ", decl)
  end

  -- Try a Decl visitor if unhandled and this isn't a plain Template,
  -- as there's generally no reason to generate code for the declaration
  -- of a template, only its specializations.
  if result == unhandled and not decl:is(ast.Template) then
    result = tryVisitors(self, self.post, decl, ast.Decl)
  end

  if result == stop then
    return stop
  end

  if result ~= unhandled then
    self.visited:push(decl)
  end

  return result
end

-- * --------------------------------------------------------------------------

--- Handles a list of decls either from the translation unit or a namespace.
--- Since these are all considered top-level, filtering is done here.
AstVisitor.handleTopLevelDeclList = function(self, list, filter)
  for decl in list:each() do
    local result
    if decl:is(ast.Namespace) then
      result = self:handleTopLevelDeclList(decl.decls, filter)
    else
      if not filter or filter(decl) then
        result = self:handleDecl(decl)
      else
      end
    end
    if result == stop then
      return stop
    end
  end
end

-- * --------------------------------------------------------------------------

AstVisitor.currentRecord = function(self)
  return self.record_stack:last()
end

-- * --------------------------------------------------------------------------

AstVisitor.begin = function(self, filter)
  self:handleTopLevelDeclList(self.astctx.translation_unit.decls, filter)
end

-- * --------------------------------------------------------------------------

AstVisitor.funcgen = function(self, prefix, ret, ...)
  local args = cmn.buffer.new() 

  local function formArgs(arg, next, ...)
    if arg then
      args:put(arg)
      if next then
        args:put ","
        formArgs(next, ...)
      end
    end
  end

  args:put "("
  formArgs(...)
  args:put ")"

  args = args:get()

  local buffer = cmn.buffer.new()

  local function declare(decl_or_type, suffix)
    local function form(c_safe, args)
      return buffer:put(
        ret, ' ',
        prefix,
        c_safe,
        suffix or "",
        args):get()
    end

    if decl_or_type:is(ast.Decl) then
      local decl = decl_or_type
      local name
      if decl:is(ast.ForwardRecord) then
        name = decl.name
      else
        name = decl.type.qname
      end
      local subsituted_args = args:gsub("%%", name)
      return form(decl:formCSafeName(), subsituted_args)
    else
      local type = decl_or_type
      if type:is(ast.TagType) or type:is(ast.TypedefType) then
        return declare(type.decl, prefix)
      else
        local subsituted_args = args:gsub("%%", type.qname)
        return form(type:formCSafeName(), subsituted_args)
      end
    end
  end

  local function call(decl_or_type)
    if decl_or_type:is(ast.Decl) then
      return buffer:put(
        prefix, 
        decl_or_type:formCSafeName()):get()
    else
      local type = decl_or_type
      if type:is(ast.TagType) then
        return call(type.decl)
      elseif type:is(ast.TypedefType) then
        return call(type.decl)
      else
        return buffer:put(
          prefix,
          type:formCSafeName()):get()
      end
    end
  end

  -- lpp takes the first return as the string to place from a macro and the
  -- second is given to the macro capture. Should maybe make a way to either
  -- specify that a function is only meant to return a lua value or some 
  -- syntax to take the first return as the capture value. Not sure what 
  -- sounds better.
  return nil, 
  {
    declare = declare,
    call = call,
  }
end

-- * --------------------------------------------------------------------------

AstVisitor.eachVisited = function(self, f)
  for visited in self.visited:each() do
    f(visited)
  end
end

return AstVisitor
