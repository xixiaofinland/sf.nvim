local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M = require('sf.ts')]])
    end,
    post_once = child.stop,
  },
})

T['get_class_name()'] = MiniTest.new_set()

return T
