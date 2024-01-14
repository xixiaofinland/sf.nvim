--- *sf.ts* Sf Treesitter
---
--- MIT License Copyright (c) 2024 Xi Xiao
---
--- ==============================================================================
---
--- Features:
--- - Provide useful APIs from Treesitter parsed Apex file.
---
--- - Functions:
---     - |SfTs.get_class_name()|.
---     - |SfTs.get_test_class_name()|.
---     - |SfTs.get_test_method_names_in_curr_file()|.
---     - |SfTs.get_current_test_method_name()|.

local T = require('sf.ts.ts')
local B = require('sf.ts.test_buf')
local M = {}

-- M.get_class_name = function()
--   T.get_class_name()
-- end

M.get_test_class_name = function()
  return T.get_test_class_name()
end

-- M.get_test_method_names_in_curr_file = function()
--   T.get_test_method_names_in_curr_file()
-- end

M.get_current_test_method_name = function()
  return T.get_current_test_method_name()
end

M.open = function()
  return B.open()
end

return M
