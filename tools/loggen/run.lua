local lake = require "lake"
local o = lake.obj
local List = require "iro.List"

---@class tools.loggen.Params
---
--- Directory to place generated files used in src/ files.
---@field generated_dir string
---
--- Directory to place obj files.
---@field build_dir string
---
--- Params for lpp.
---@field lpp_params lake.obj.Lpp.PreprocessParams
---
--- Params for cpp.
---@field cpp_params lake.obj.Cpp.CompileParams
---
--- List that compiled objs will be pushed to.
---@field out_objs iro.List

--- Perform generation of logging stuff. Returns a lake.Task that should be 
--- a dependency of things in src/.
---
---@param params tools.loggen.Params
---@return lake.Task 
return function(params)
  local loggen_task = lake.task "loggen"

  local generated_dir = params.generated_dir.."/loggen"
  local build_dir = params.build_dir.."/tools/loggen"

  local logdefs = List {}

  for logdef in lake.utils.glob "src/**/*.logdef.lua" :each() do
    print(logdef)
    logdefs:push(o.Lua(logdef))
  end

  local cat_decls = 
    o.Lpp "tools/loggen/category_decls.lpp" 
      :preprocess(generated_dir.."/log_categories.h", params.lpp_params)

  local cat_defs_o =
    o.Lpp "tools/loggen/category_defs.lpp"
      :preprocessToCpp(generated_dir.."/log_categories.cpp", params.lpp_params)
      :compile(build_dir.."/category_defs.lpp.cpp.o", params.cpp_params)

  for logdef in logdefs:each() do
    print(logdef)
    cat_decls.task:dependsOn(logdef.task)
    cat_defs_o.task:dependsOn(logdef.task)
  end

  params.out_objs:push(cat_defs_o)

  loggen_task:dependsOn(cat_decls.task)
  loggen_task:dependsOn(cat_defs_o.task)

  return loggen_task
end
