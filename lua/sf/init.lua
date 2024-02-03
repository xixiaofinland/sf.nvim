--- *sf* Global features for sf.nvim
--- *Sf*
---
--- =====================================================
---
--- Features:
---
--- - global fields shared among all sf modules.
--- - global functions shared among all sf modules.

local U = require('sf.util');
local Sf = {}

--- It stores the last executed Apex test command so we can re-run by `require('sf.term').repeat_last_tests()`.
Sf.last_tests = ''

--- It's meant to be used by statusline (like lualine) to display target_org information.
Sf.target_org = ''

-- Module functionality =======================================================
--- Return `target_org` field value or throw error when it's empty
---
---@return string
Sf.get = function()
  U.is_empty(Sf.target_org)

  return Sf.target_org
end

return Sf
