local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M = require('sf')]])
      child.lua([[U = require('sf.util')]])
    end,
    post_once = child.stop,
  },
})

T['get_target_org()'] = MiniTest.new_set()

T['get_target_org()']['it works to get target_org value'] = function()
  child.lua([[U.target_org = 'sandbox1']])
  eq(child.lua([[return M.get_target_org()]]), 'sandbox1')
end

T['get_target_org()']['target_org empty then err'] = function()
  expect.error(function() child.lua([[M.get_target_org()]]) end)
end

return T
