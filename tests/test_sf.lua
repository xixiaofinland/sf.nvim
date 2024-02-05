local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local child = MiniTest.new_child_neovim()

local T = new_set({
  hooks = {
    pre_case = function()
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      child.lua([[M = require('sf')]])
    end,
    post_once = child.stop,
  },
})

T['error'] = function()
  expect.error(child.lua([[M.get()]]))
  -- eq(child.lua([[return M.compute({'a', 'b'})]]), { 'Hello a', 'Hello b' })
end

return T
