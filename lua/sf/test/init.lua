local Prompt = require('sf.test.prompt')
local p = Prompt:new()
local M = {}

M.open = function()
  p:open()
end

M.toggle = function()
  p:toggle()
end

M.build_selected_tests_cmd = function()
  p:build_selected_tests_cmd()
end

return M
