local lake = require "lake"
local cc = require "lake.compile_commands" ()
local cclpp = require "lake.compile_commands" ()
local o = lake.obj
local List = require "iro.List"
local fs = require "iro.fs"
local time = require "iro.time"

local start_time = time.Point.monotonic()
lake.registerHook("final", function(success)
  local total_time = time.Point.monotonic() - start_time

  io.write("build ")

  if success then
    io.write(lake.flair.green, "succeeded ")
  else
    io.write(lake.flair.red, "failed ")
  end

  io.write(lake.flair.reset, "in ", total_time:pretty(), '\n')
end)

local cfg
local success, user_cfg = pcall(require, "build_config.user")
if success then
  cfg = user_cfg
else  
  cfg = require "build_config.debug"
end

local function set(t, k, v)
  local dot = k:find "%."
  if dot then
    local tk = k:sub(1, dot-1)
    if not t[tk] then
      error("unknown key "..tk)
    end

    set(t[tk], k:sub(dot+1), v)
  else
    if t[k] == nil then
      error("unknown key "..k)
    end
    if v == "true" then
      t[k] = true
    elseif v == "false" then
      t[k] = false
    else
      local as_num = tonumber(v)
      if as_num then
        t[k] = as_num
      else
        t[k] = v
      end
    end
  end
end

for arg in lake.cliargs:each() do
  if arg:find "^%." then
    local setting = arg:sub(2)
    local k, v = setting:match "([%.%w%d]+)=(.*)"
    set(cfg, k, v)
  end
end

local cwd = fs.cwd()

lake.setMaxJobs(cfg.max_jobs or 8)

--- Directory where *all* build artifacts go. This allows a build of ecs or 
--- any of the tools to be cleanly wiped completely by simply deleting this 
--- directory.
local build_dir = cwd.."/"..cfg.build_dir

--- Directory in which generated files live. This is separated such that we 
--- can tell build tools that this is an include, require, import, etc. dir
--- without the stuff being mixed with other build artifacts.
local generated_dir = build_dir.."/_gen"

local enable_tracy = cfg.tracy.enabled
local asan = cfg.asan

if lake.os == "windows" then
	asan = false
end

-- TODO(sushi) command for cleaning data/
-- TODO(sushi) command for code hot reloading
-- TODO(sushi) command for running tests
if lake.cliargs[1] == "clean" then
  fs.rm(build_dir, true, true)
  return false
end

local objs = List {}

local shared_libs = List(cfg.link.libs)

if cfg.hreload then
  shared_libs:push "hreload"
end

local lib_dirs = List(cfg.link.lib_dirs)
local include_dirs = List(cfg.cpp.include_dirs)

include_dirs:push(generated_dir)

local defines = cfg.cpp.defines

local resource_dir_arg
if lake.os == "windows" then
  defines.ECS_LPPCLANG_LIB = "lib/lppclang.dll"
  defines.ECS_CLANG_EXE = "third_party/bin/win32/clang"
elseif lake.os == "linux" then
  defines.ECS_LPPCLANG_LIB = "lib/lppclang.so"
  defines.ECS_CLANG_EXE = "third_party/bin/linux/clang"
  defines.ECS_CLANG_RESOURCE_DIR = cwd.."/third_party/lib/clang/22"
  resource_dir_arg = defines.ECS_CLANG_RESOURCE_DIR
  if enable_tracy then
    defines.ECS_ENABLE_PROFILING = true
  end
else
  error "unhandled os"
end

defines.IRO_ENABLE_INTERNAL_LOGGING = 1

if cfg.gen_pretty_print then
  defines.ECS_GEN_PRETTY_PRINT = 1
end

if cfg.hreload then
  defines.ECS_HOT_RELOAD = 1
  shared_libs:push "hreload"
end

if cfg.cpp.debug_info then
  defines.ECS_DEBUG = 1
  defines.HASH_CACHE_ENABLED = 1
end

if cfg.cpp.opt == "speed" then
  defines.NDEBUG = true
end

if cfg.tracy.enabled then
  defines.TRACY_ENABLE = 1
  defines.TRACY_CALLSTACK = cfg.tracy.callstack
  defines.TRACY_SAMPLE_HZ = cfg.tracy.sample_hz
end

---@type lake.obj.Cpp.CompileParams
local cpp_params = 
{
  std = cfg.cpp.std,

  defines = defines,

  include_paths = include_dirs,

  opt = cfg.cpp.opt,
  debug_info = cfg.cpp.debug_info,

  noexceptions = true,
  nortti = true,

  asan = asan,

  patchable_function_entry = 16,

  time_trace = true,

  resource_dir = resource_dir_arg,
}

if cfg.hreload then
  cpp_params.pic = true
end

---@type lake.obj.Lpp.PreprocessParams
local lpp_params = 
{
  require_dirs = cfg.lpp.require_dirs,
  cpath_dirs = cfg.lpp.cpath_dirs,
  import_dirs = cfg.lpp.import_dirs,
  gen_meta = cfg.lpp.gen_meta,
  cmd_callback = cclpp:cmdCallback(),
}

---@type lake.obj.Exe.LinkParams
local link_params = 
{
  shared_libs = shared_libs,
  lib_dirs    = lib_dirs,

  asan = asan,
}

local iro_objs = List {}
lake.utils.indir("include/iro", function()
  local iro = require "project" ()

  -- TODO(sushi) lake.utils helper for merging tables like this.
  --             Dunno, the way I decided to specify defines kinda sucks 
  --             but its simple at least.
  for _, def in ipairs(iro.defines) do
    table.insert(cpp_params.defines, def)
  end

  for k,v in pairs(iro.defines) do
    if type(k) ~= "number" then
      cpp_params.defines[k] = v
    end
  end

  cpp_params.cmd_callback = cc:cmdCallback()

  for source in iro.sources:each() do
    local output = build_dir.."/iro/"..source.path..".o"
    iro_objs:push(source:compile(output, cpp_params))
  end
end)

--- Form the meta arg that the relfection system will use to pass along to 
--- lppclang the cpp params we will be compiling the resulting cpp files 
--- with. Note that we must do this after iro has been imported such that 
--- its defines and stuff are included.
local cpp_args_noio = require "lake.driver.clang" .noio(cpp_params)

local meta_arg = "--cargs="
for _,arg in ipairs(cpp_args_noio) do
  meta_arg = meta_arg..arg..","
end

lpp_params.meta_args = List { meta_arg }

cpp_params.cmd_callback = cc:cmdCallback()

if lake.cliargs[1] == "doc" then

  ---@type tools.docgen.Params
  local docgen_params = 
  {
    build_dir = build_dir,
    lpp_params = lpp_params,
    cpp_params = cpp_params,
    cwd = cwd,
  }

  require "tools.docgen.run" (docgen_params)

  return
end

---@type tools.loggen.Params
local loggen_params = 
{
  generated_dir = generated_dir,
  build_dir = build_dir,
  lpp_params = lpp_params,
  cpp_params = cpp_params,
  out_objs = List{}
}

local loggen = require "tools.loggen.run" (loggen_params)
local loggen_objs = loggen_params.out_objs

local lh_params = require "iro.tbl" .deepExtend(lpp_params,
{
  meta_args = List { "--lh-compile", meta_arg }
})

local lh_task = lake.task "build lh files"

for lfile in lake.utils.glob("src/**/*.lh"):each() do
  local h_output = generated_dir.."/"..lfile..".h"
  
  local lh = o.Lpp(lfile):preprocess(h_output, lh_params)

  local guard_id = lfile:gsub("[/%-%.]", "_")
  
  local guard = 
    lake.task("guard "..h_output)
      :cond(function() return false end)
      :dependsOn(lh.task)
      :recipe(function()
        local f = io.open(h_output)
        local c = f:read("*a")
        f:close()

        f = io.open(h_output, "w+")
        f:write(
          '#ifndef '..guard_id..
        '\n#define '..guard_id..
        '\n'..c..
        '\n#endif')
        f:close()

        -- lake.flair.writeSuccessOnlyOutput("guarded "..
        --   lake.utils.getPathBasename(h_output))
      end)

  lh_task:dependsOn(guard)
end

-- do return end

---@return lake.obj.Exe
local function buildTest(name)
  ---@type ecs.test.Params
  local test_params = 
  {
    build_dir = build_dir,
    lpp_params = lpp_params,
    cpp_params = cpp_params,
    link_params = link_params,
    lh_task = lh_task,
  }

  local test_objs = require("tests."..name..".build") (test_params)

  if test_objs then
    for obj in test_objs:each() do
      obj.task:dependsOn(loggen)
      obj.task:dependsOn(lh_task)
    end

    test_objs:pushList(iro_objs)
    test_objs:pushList(loggen_objs)

    local exe = o.Exe (build_dir.."/tests/"..name.."/run")
    exe:link(test_objs, link_params)

    return exe
  end
end

local function buildAndRunTest(name)
  local exe = buildTest(name)

  if not exe then
    do return end
    -- error("test "..name.." did not return an Exe to run!")
  end
  
  lake.task("test "..name)
    :dependsOn(exe.task)
    :cond(function() return true end)
    :recipe(function()
      local time, result = lake.utils.timed(function()
        return lake.async.run { exe.path }
      end)

      io.write(result.output)

      if result.exit_code ~= 0 then
        io.write("test '", name,  "' ", lake.flair.red, "failed", 
                 lake.flair.reset, "!\n")
      else
        io.write("test '", name, "' ", lake.flair.green, "succeeded", 
                 lake.flair.reset, "! (in ", time:pretty(), ")\n")
      end
    end)
end


if lake.cliargs[1] == "test" then
  local testname = lake.cliargs[2]

  if not testname then
    error("expected the name of a test to run (a directory in tests/)")
  end

  buildAndRunTest(testname)

  cc:write "compile_commands.json"

  return
end

-- buildTest "asset-building"



for lfile in lake.utils.glob("src/**/*.lpp"):each() do
  local cpp_output = build_dir.."/"..lfile..".cpp"
  local o_output = cpp_output..".o"

  local cpp = o.Lpp(lfile):preprocessToCpp(cpp_output, lpp_params)
  local obj = cpp:compile(o_output, cpp_params)

  cpp.task:dependsOn(lh_task)

  objs:push(obj)
end

for cfile in lake.utils.glob("src/**/*.cpp"):each() do
  local output = build_dir.."/"..cfile..".o"
  local obj = o.Cpp(cfile):compile(output, cpp_params)
  objs:push(obj)
end

--- For now assume that any obj file depends on log generation.
for obj in objs:each() do
  obj.task:dependsOn(loggen)
end

if enable_tracy then
  local tracy_o = 
    o.Cpp "third_party/tracy/include/TracyClient.cpp"
      :compile(build_dir.."/tracy/TracyClient.cpp.o", cpp_params)

  objs:push(tracy_o)
end

objs:pushList(iro_objs)
objs:pushList(loggen_objs)

if lake.cliargs[1] == "patch" then
  o.SharedLib("_build/ecs_patch"..lake.cliargs[2])
    :link(objs, link_params)
else
  if lake.os == "windows" then
    o.Exe "_build/ecs.exe" :link(objs, link_params)
  else
    o.Exe "_build/ecs" :link(objs, link_params)
  end
end

local hrf = build_dir.."/ecs.hrf"

local f = io.open(hrf, "w+")
for obj in objs:each() do
  if not obj.path:find ".lua.o" then
    f:write("+o", obj.path, '\n')
  end
end
f:close()

cc:write "compile_commands.json"
cclpp:write "compile_commands_lpp.json"
