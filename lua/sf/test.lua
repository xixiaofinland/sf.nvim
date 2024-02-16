local S = require('sf')
local Term = require('sf.term')
local p = require('sf.test.prompt'):new()
local Test = {}

--- open a top window that displays the list of Apex tests in the current file.
--- Allows to select/deselect tests and execute.
Test.open = function()
  p:open()
end

--- local method. Do not call it directly.
Test._toggle = function()
  p:toggle()
end

--- local method. Do not call it directly.
Test._run_selected = function()
  local cmd = p:build_selected_tests_cmd() .. ' -o ' .. S.get()
  p:close()
  Term.run(cmd)
  S.last_tests = cmd
end

return Test
