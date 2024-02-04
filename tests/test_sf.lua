local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

local T = new_set({
  hooks = {
    pre_case = function()
      M = require('sf')
      T = require('sf.term')
      A = require('telescope')
      U = require('sf.ts')
    end,
    -- post_once = child.stop,
  },
})

T['error'] = function()
  expect.error(function()
    M.get()
  end)
end

return T
