--- Currently just a generic 'game' category. Game logging will become
--- much more involved later on when we get to outputting to specific files
--- and separating logging between server and client.

local def = require "core.logging.def"

def.category("game", { verbosity = "Info" })
