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

  -- compileLpp "src/reflect/RTR_Pretty.lpp"
  compileLpp "src/reflect/Packing.lpp"
  compileLpp "src/sdata/SourceDataFile.lpp"
  compileLpp "src/sdata/SourceData.lpp"
  compileLpp "src/sdata/SourceDataParser.lpp"
  compileLpp "tests/packing/main.lpp"

  return objs
end
