local O = require "sforg.org"
local M = {}

function M.get()
  return O.target_org
end

function M.fetch()
  O.fetch()
end

function M.set()
  O.set()
end

function M.setGlobal()
  O.setGlobal()
end

return M
