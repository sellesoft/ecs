local lake = require "lake"
local o = lake.obj
local List = require "iro.List"

---@param params ecs.test.Params
return function(params)
  local objs = List {}

  local function compileLpp(lfile)
    local cpp = params.build_dir.."/"..lfile..".cpp"
    objs:push(
      o.Lpp(lfile)
        :preprocessToCpp(cpp, params.lpp_params)
        :compile(cpp..".o", params.cpp_params))
  end

  compileLpp "tests/logging/main.lpp"

  return objs
end
