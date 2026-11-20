package.loaded.socket = import "AgSocket"
local mobdebug = require "mobdebug"
os.exit = mobdebug.done
return mobdebug
