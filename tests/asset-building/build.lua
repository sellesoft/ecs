local lake = require "lake"
local o = lake.obj
local List = require "iro.List"

return function(
    build_dir, 
    lpp_params, 
    cpp_params,
    link_params,
    iro_objs)

  local objs = List {}
  objs:pushList(iro_objs)

  local function compileLpp(lfile)
    local cpp = build_dir.."/"..lfile..".cpp"
    objs:push(
      o.Lpp(lfile)
        :preprocessToCpp(cpp, lpp_params)
        :compile(cpp..".o", cpp_params))
  end

  compileLpp "src/asset/Ref.lpp"
  compileLpp "src/reflect/RTR.lpp"
  compileLpp "src/reflect/RTR_Pretty.lpp"
  compileLpp "src/graphics/CompiledTexturePNG.lpp"
  compileLpp "src/graphics/CompiledTexture.lpp"
  compileLpp "src/graphics/CompiledShader.lpp"
  compileLpp "src/asset/CompiledData.lpp"
  compileLpp "src/asset/Packing.lpp"
  compileLpp "src/sdata/SourceDataFile.lpp"
  compileLpp "src/sdata/SourceData.lpp"
  compileLpp "src/sdata/SourceDataParser.lpp"
  compileLpp "tests/asset-building/main.lpp"

  local exe = o.Exe(build_dir.."/tests/asset-building/run")
  exe:link(objs, link_params)

  return exe
end
