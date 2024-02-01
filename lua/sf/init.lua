local U = require('sf.util');

local M = {}

M.last_tests = ''
M.target_org = ''

M.get = function()
  U.is_empty(M.target_org)

  return M.target_org
end

M.get_target_org = function()
  return M.target_org
end

return M
