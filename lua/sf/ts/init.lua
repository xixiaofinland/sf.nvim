--- *sf.ts* Sf Treesitter
---
--- MIT License Copyright (c) 2024 Xi Xiao
---
--- ==============================================================================
---
--- Features:
--- - Provide useful APIs from Treesitter parsed Apex file.
---

local T = require('sf.ts.ts')
local Prompt = require('sf.ts.prompt')
local p = Prompt:new()
local M = {}

M.open = function()
  p:open()
end

M.toggle = function()
  p:toggle()
end

M.get_test_class_name = function()
  return T.get_test_class_name()
end

M.get_test_method_names_in_curr_file = function()
  T.get_test_method_names_in_curr_file()
end

M.get_current_test_method_name = function()
  return T.get_current_test_method_name()
end

M.build_selected_tests_cmd = function()
  return p:build_selected_tests_cmd()
end

return M
