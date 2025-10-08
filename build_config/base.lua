local List = require "iro.List"

return 
{
  build_dir = "_build",

  max_jobs = 8,

  cpp = 
  {
    include_dirs = List
    {
      "src",
      "include",
      "third_party/include",
      "third_party/tracy/include",
    },

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
    libs = List
    {
      "X11",
      "Xrandr",
      "Xcursor",
      "vulkan",
      "shaderc_combined",
      "luajit",
      "hreload",
    },

    lib_dirs = List
    {
      "lib",
      "third_party/lib",
      "third_party/lib/clang",
      "third_party/lib/shaderc",
    },
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
