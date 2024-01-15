local org = require "sf.org.org"
local M = {}

function M.get()
  if org.target_org == '' then
    return ''
  end

  return '-o ' .. org.target_org
end

function M.get_target_org()
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
