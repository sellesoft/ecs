local lake = require "lake"
local o = lake.obj
local List = require "iro.List"

---@param params ecs.test.Params
return function(params)
  local objs = List {}

  local function compileLpp(lfile)
    local cpp_path = params.build_dir.."/"..lfile..".cpp"
    
    local cpp = o.Lpp(lfile):preprocessToCpp(cpp_path, params.lpp_params)
    cpp.task:dependsOn(params.lh_task)

    local obj = cpp:compile(cpp_path..".o", params.cpp_params)
    objs:push(obj)
  end

  compileLpp "src/reflect/Packing.lpp"
  compileLpp "src/reflect/Unpacking.lpp"
  compileLpp "src/reflect/CompiledData2.lpp"
  compileLpp "src/reflect/rtr.lpp"
  compileLpp "src/reflect/rtr_pretty.lpp"
  compileLpp "src/sdata/SourceDataFile.lpp"
  compileLpp "src/sdata/SourceData.lpp"
  compileLpp "src/sdata/SourceDataParser.lpp"
  compileLpp "src/build/BuildSystem.lpp"
  compileLpp "src/build/Target.lpp"
  compileLpp "tests/compile-data/main.lpp"
  compileLpp "src/core/logging/core.lpp"

  return objs
end
