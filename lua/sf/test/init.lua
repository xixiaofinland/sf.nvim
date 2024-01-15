local Prompt = require('sf.test.prompt')
local p = Prompt:new()
local M = {}

M.open = function()
  p:open()
end

M.toggle = function()
  p:toggle()
end

return M
