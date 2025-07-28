--- 
--- Helper for dumping our ast.
---

local Type = require "iro.Type"
local List = require "iro.List"
local buffer = require "string.buffer"

---@class reflect.AstDump.Colors
local colors = 
{
  black   = "\x1b[30m",
  red     = "\x1b[31m",
  green   = "\x1b[32m",
  yellow  = "\x1b[33m",
  blue    = "\x1b[34m",
  magenta = "\x1b[35m",
  cyan    = "\x1b[36m",
  white   = "\x1b[37m",
  reset   = "\x1b[0m"
}

--- @class reflect.AstDump : iro.Type
---
--- @field depth number
---
--- @field col reflect.AstDump.Colors
---
--- @field buffer any
---
--- @field node_stack iro.List
---
local AstDump = Type.make()

local AstDumpNode = Type.make()

AstDumpNode.new = function(name)
  local o = {}
  o.node_name = name
  o.tags = List {}
  o.children = List {}
  return setmetatable(o, AstDumpNode)
end

---@return reflect.AstDump
AstDump.new = function()
  local o = {}
  o.depth = 0
  o.col = colors
  o.buffer = buffer.new()
  o.node_stack = List{}
  return setmetatable(o, AstDump)
end

AstDump.write = function(self, ...)
  local function impl(x, ...)
    if x ~= nil then
      self.buffer:put(
        tostring(x):gsub("\n", "\n"..(" "):rep(self.depth)))
    end
  end

  impl(...)
end

AstDump.node = function(self, name, func)
  local node = AstDumpNode.new(name)
  local prev = self.node_stack:last()
  if prev then
    prev.children:push(node)
  end

  self.node_stack:push(node)
  func(self)
  self.node_stack:pop()

end

