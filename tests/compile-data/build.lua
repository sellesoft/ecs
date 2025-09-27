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

  compileLpp "src/reflect/Packing.lpp"
  compileLpp "src/reflect/CompiledData.lpp"
  compileLpp "src/reflect/rtr.lpp"
  compileLpp "src/reflect/rtr_pretty.lpp"
  compileLpp "src/sdata/SourceDataFile.lpp"
  compileLpp "src/sdata/SourceData.lpp"
  compileLpp "src/sdata/SourceDataParser.lpp"
  compileLpp "src/build/BuildSystem.lpp"
  compileLpp "src/build/Target.lpp"
  compileLpp "tests/compile-data/main.lpp"

  return objs
end
