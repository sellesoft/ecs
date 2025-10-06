local ast = require "reflect.ast"
local List = require "iro.List"
local Type = require "iro.Type"
local sbuf = require "string.buffer"

---@class reflect.ast.Encoder : iro.Type
---@field node_table table
---@field node_list iro.List
local Encoder = Type.make()

Encoder.new = function()
  local o = {}
  o.node_table = {}
  o.node_list = List {}
  return setmetatable(o, Encoder)
end

Encoder.encode_node = function(self, node)
  local result = {}
  result.encoding = "node"

  if self.node_table[node] then
    result.node_ref = self.node_table[node].index
    return result
  end

  local encoded = {}
  encoded.index = self.node_list:len() + 1
  result.node_ref = encoded.index

  self.node_table[node] = encoded
  self.node_list:push(encoded)

  encoded.node_kind = node.__type.node_name

  encoded.data = {}
  for k,v in pairs(node) do
    if k ~= "__type" and k ~= "__index" then
      if type(v) ~= "function" then
        encoded.data[k] = self:encode_value(v)
      end
    end
  end

  return result
end

Encoder.encode_value = function(self, val)
  if "table" == type(val) then
    if val.__type and val.__type.is_ast_node then
      return (self:encode_node(val))
    elseif List:isTypeOf(val) then
      return (self:encode_list(val))
    else
    end
  else
    return val
  end
end

Encoder.encode_list = function(self, list)
  local result = {}
  result.encoding = "list"
  result.data = {}

  for elem in list:each() do
    local encoded = self:encode_value(elem)
    table.insert(result.data, encoded)
  end

  return result
end

return function(node)
  local data = {}

  local encoder = Encoder.new()
  data.root = encoder:encode_node(node)
  data.node_list = encoder.node_list

  local buf = sbuf.new()
  local encoded = buf:encode(data):get()

  local decoded = sbuf.decode(encoded)

  require "iro.util" .dumpValue(decoded, 3)
end
