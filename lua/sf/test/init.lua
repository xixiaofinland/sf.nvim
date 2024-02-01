local Org = require('sf.org')
local Term = require('sf.term')
local p = require('sf.test.prompt'):new()
local M = {}

M.open = function()
  p:open()
end

M.toggle = function()
  p:toggle()
end

M.run_selected = function()
  local cmd = p:build_selected_tests_cmd() .. ' -o ' .. Org.get()
  p:close()
  Term.run(cmd)
  Term.lastTests = cmd
end

return M
