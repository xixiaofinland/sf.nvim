local org = require "sf.org.org"
local M = {}

function M.get()
  if org.target_org == nil then
    return ''
  end

  return org.target_org
end

function M.fetch()
  org.fetch()
end

function M.set()
  org.set()
end

function M.setGlobal()
  org.setGlobal()
end

return M
