local lake = require "lake"
local o = lake.obj

---@param params ecs.test.Params
return function(params)
  local function preprocessLpp(lfile)
    local cpp = params.build_dir.."/"..lfile..".cpp"
    o.Lpp(lfile)
      :preprocessToCpp(cpp, params.lpp_params)
      :compile(cpp..".o", params.cpp_params)
  end

  preprocessLpp "tests/ast-visit/astvisit.lpp"
end
