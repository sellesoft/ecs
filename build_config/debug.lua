return require "iro.tbl" .deepExtend(require "build_config.base", 
{
  cpp = 
  {
    opt = "none",
    debug_info = true,

    defines = 
    {
      ECS_DEBUG=1,
    }
  },
})
