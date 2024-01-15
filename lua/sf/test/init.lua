local Prompt = require('sf.test.prompt')
local Org = require('sf.org')
local Term = require('sf.term')
local p = Prompt:new()
local M = {}

M.open = function()
  p:open()
end

M.toggle = function()
  p:toggle()
end

M.run_selected = function()
  local cmd = p:build_selected_tests_cmd() .. Org.get()
  p:close()
  Term.run(cmd)
end

return M
