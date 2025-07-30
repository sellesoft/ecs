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
--- @field root_node AstDumpNode
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
        (tostring(x):gsub("\n", "\n"..(" "):rep(self.depth))))
      impl(...)
    end
  end

  impl(...)
end

AstDump.node = function(self, name, func)
  local node = AstDumpNode.new(name)
  self.root_node = self.root_node or node

  local prev = self.node_stack:last()
  if prev then
    prev.children:push(node)
  end

  self.node_stack:push(node)
  func(self)
  self.node_stack:pop()
end

AstDump.typenode = function(self, name, func)
  local node = AstDumpNode.new(name)
  node.is_type = true

  local prev = self.node_stack:last()
  if prev then
    prev.children:push(node)
  end

  self.node_stack:push(node)
  func(self)
  self.node_stack:pop()
end

AstDump.tag = function(self, name, data)
  local node = self.node_stack:last()
  node.tags:push {name = name, data = data}
end

AstDump.inline_name = function(self, name)
  local node = self.node_stack:last()
  node.inline_name = name
end

AstDump.form = function(self)

  local node_state_stack = List {}

  local function write(...)
    local function impl(x, ...)
      if x ~= nil then
        self.buffer:put(tostring(x))
        impl(...)
      end
    end
    impl(...)
  end

  local function writeBranches(is_tag)
    local function colored(x)
      write(colors.cyan, x, colors.reset)
    end

    for node_state,i in node_state_stack:eachWithIndex() do
      local last_node = i == node_state_stack:len()

      if node_state == "normal" then
        if is_tag and last_node then
          colored ">"
        else
          colored "|"
        end
      elseif node_state == "at_last_child" then
        if last_node then
          colored "`"
        else
          colored " "
        end
      end

      if not last_node then
        write " "
      end
    end
  end

  local function impl(node)
    writeBranches()
    if not node_state_stack:isEmpty() then
      write('-')
    end
    local nodecol
    if node.is_type then
      nodecol = colors.magenta
    else
      nodecol = colors.yellow
    end

    write(nodecol, node.node_name, colors.reset)
    if node.inline_name then
      write(' ', node.inline_name)
    end
    write "\n"
    node_state_stack:push "normal"
    for tag in node.tags:each() do
      writeBranches(true)
      write(" ", colors.green, tag.name, colors.reset, ": ", tag.data, "\n")
    end
    for child,i in node.children:eachWithIndex() do
      if i == node.children:len() then
        node_state_stack:pop()
        node_state_stack:push "at_last_child"
      end
      impl(child)
    end
    node_state_stack:pop()
  end

  impl(self.root_node)

  io.write(self.buffer:get(), '\n')
end

return AstDump
