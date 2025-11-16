local List = require "iro.List"
local lake = require "lake"
local os = require "iro.os"
local fs = require "iro.fs"

local cwd = fs.cwd()

local shared_libs = List {}

local lib_dirs = List 
{
  cwd.."/lib",
}

local include_dirs = List
{
  cwd.."/src",
  cwd.."/include",
  cwd.."/third_party/include",
}

if lake.os == "windows" then

  shared_libs = List
  {
    "user32",
    "gdi32",
    "Ws2_32",
    "vulkan-1",
    "shaderc_combined"
  }

  local vksdk = os.getEnvVar "VK_SDK_PATH"

  if not vksdk then
    error("VK_SDK_PATH must be defined on Windows to tell where Vulkan is "..
          "installed.")
  end

  vksdk = vksdk:gsub("\\", "/")

  if vksdk:sub(-1) == '\0' then
    vksdk = vksdk:sub(1,-2)
  end

  lib_dirs:push(vksdk.."/Lib")
  include_dirs:push(vksdk.."/Include")

elseif lake.os == "linux" then

  shared_libs = List
  {
    "X11",
    "Xrandr",
    "Xcursor",
    "vulkan",
    "shaderc_combined",
    "luajit",
    "hreload",
  }

  lib_dirs:push(cwd.."/third_party/lib/luajit/linux")
  lib_dirs:push(cwd.."/third_party/lib/clang")
  lib_dirs:push(cwd.."/third_party/lib/shaderc")

  include_dirs:push(cwd.."/third_party/tracy/include")

end

return 
{
  build_dir = "_build",

  max_jobs = 8,

  cpp = 
  {
    include_dirs = include_dirs,
    std = "c++23",
    opt = "speed",
    debug_info = false,
  },

  lpp = 
  {
    require_dirs = List
    {
      "src",
    },

    import_dirs = List
    {
      "src",
    },

    cpath_dirs = List
    {
      "lib",
    },

    gen_meta = false,
  },

  link = 
  {
    libs = shared_libs,
    lib_dirs = lib_dirs,
  },

  tracy = 
  {
    enabled = false,
    callstack = 2,
    sample_hz = 10000,
  },

  hreload = false,
  asan = false,
  gen_pretty_print = false,
}
