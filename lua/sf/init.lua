--- *sf* A plugin for Salesforce development
--- *Sf*
---
--- =====================================================
---
--- Features:
---
--- - global fields shared among all sf modules.
--- - global functions shared among all sf modules and external tools

local U = require('sf.util');
local M = {}

--- It stores the last executed Apex test command so we can re-run by `require('sf.term').repeat_last_tests()`.
M.last_tests = ''

--- It's meant to be used by statusline (like lualine) to display target_org information.
M.target_org = ''

-- Module functionality =======================================================
--- Return `target_org` field value or throw error when it's empty
---
---@return string
M.get = function()
  U.is_empty(M.target_org)

  return M.target_org
end

return M
