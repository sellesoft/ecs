--- 
--- 'test' for anything. Primarily adding so that I can incrementally work
--- on reimplementing various things in an isolated manner.
---

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

  compileLpp "src/game/shared/component/Component.lpp"
  -- compileLpp "tests/sandbox/main.lpp"

  -- local exe = o.Exe(build_dir.."/tests/compile-data/run")
  -- exe:link(objs, link_params)

  return exe
end
