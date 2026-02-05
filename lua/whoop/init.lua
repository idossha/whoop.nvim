local M = {}

M.config = require("whoop.config")
M.auth = require("whoop.auth")
M.api = require("whoop.api")
M.storage = require("whoop.storage")

function M.setup(opts)
  M.config.setup(opts)
end

return M
