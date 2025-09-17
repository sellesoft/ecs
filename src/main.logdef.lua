local logdef = require "core.logging.def"

-- Category meant to be used only by the main function.
logdef.category("main",
{
  verbosity = "Info"
})

-- TODO(sushi) put elsewhere.
logdef.category("engine",
{
  verbosity = "Info",
})
