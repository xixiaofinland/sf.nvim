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

--- It stores the command executed by run_all_tests_in_this_file() and run_current_test()
--- repeat_last_tests() uses it to re-run tests
Sf.last_tests = ''

--- Almost all commands executes against `target_org`. It's a good practice to display it in the statusline.
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
