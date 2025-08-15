local lake = require "lake"
local cc = require "lake.compile_commands" ()
local o = lake.obj
local List = require "iro.List"
local fs = require "iro.fs"

local cwd = fs.cwd()

lake.setMaxJobs(8)

local build_dir = cwd.."/_build"

-- TODO(sushi) command for cleaning data/
-- TODO(sushi) command for code hot reloading
-- TODO(sushi) command for running tests
if lake.cliargs[1] == "clean" then
  fs.rm(build_dir, true, true)
  return false
end

-- Toggles compiling address sanitizer into the project.
-- TODO(sushi) enforce enabling this when tests are run. Don't have a command
--             for doing that yet, though.
-- TODO(sushi) command for building with/without this since it doesn't work
--             under debuggers.
local asan = true

local objs = List {}

local shared_libs = List
{
  "X11",
  "Xrandr",
  "Xcursor",
  "vulkan",
  "shaderc_combined",
  -- TODO(sushi) make building iro with lua state optional.
  --             I mean yeah, I could just compile iro manually here instead
  --             of calling into it, but I dont WANT TO.
  "luajit",
}

local static_libs = List
{
  "vulkan",
  "shaderc_combined",
}

local include_dirs = List 
{
  cwd.."/src",
  cwd.."/include",
  cwd.."/third_party/include",
}

local lib_dirs = List
{
  cwd.."/lib",
  cwd.."/third_party/lib",
  cwd.."/third_party/lib/clang",
  cwd.."/third_party/lib/shaderc",
}

---@type lake.obj.Cpp.CompileParams
local cpp_params = 
{
  defines = 
  {
    ECS_DEBUG = 1,
  },

  include_paths = include_dirs,

  opt = 'none',
  debug_info = true,

  noexceptions = true,
  nortti = true,

  asan = asan,
}

---@type lake.obj.Lpp.PreprocessParams
local lpp_params = 
{
  require_dirs = List { "src" },
  cpath_dirs = List { "lib" },
  import_dirs = List { "src" },

  cmd_callback = function(cmd, file)
    if file:find "main" then
      local f = io.open("cmd.txt", "w")
      f:write("lldb -- "..table.concat(cmd, " "))
      f:close()
    end
  end
}

---@type lake.obj.Exe.LinkParams
local link_params = 
{
  shared_libs = shared_libs,
  static_libs = static_libs,
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

---@return lake.obj.Exe
local function buildTest(name)
  return require("tests."..name..".build") (
    build_dir,
    lpp_params,
    cpp_params,
    link_params,
    iro_objs)
end

local function buildAndRunTest(name)
  local exe = buildTest(name)

  if not exe then
    error("test "..name.." did not return an Exe to run!")
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

  return
end

-- buildTest "asset-building"

for lfile in lake.utils.glob("src/**/*.lpp"):each() do
  local cpp_output = build_dir.."/"..lfile..".cpp"
  local o_output = cpp_output..".o"
  objs:push(
    o.Lpp(lfile)
      :preprocessToCpp(cpp_output, lpp_params)
      :compile(o_output, cpp_params))
end

for cfile in lake.utils.glob("src/**/*.cpp"):each() do
  local output = build_dir.."/"..cfile..".o"
  objs:push(o.Cpp(cfile):compile(output, cpp_params))
end

objs:pushList(iro_objs)

o.Exe "_build/ecs" :link(objs, link_params)

cc:write "compile_commands.json"

