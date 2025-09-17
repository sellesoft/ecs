--- 
--- File that just defines the structure of test build parameters.
---

---@class ecs.test.Params
---
--- The directory in which build artifacts should go.
---@field build_dir string
---
--- Parameters for building lpp files.
---@field lpp_params lake.obj.Lpp.PreprocessParams
---
--- Parameters for building cpp files.
---@field cpp_params lake.obj.Cpp.CompileParams
---
--- Parameters for linking the test exe.
---@field link_params lake.obj.Exe.LinkParams

