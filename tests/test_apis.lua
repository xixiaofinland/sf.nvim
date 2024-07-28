local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.lua([[Sf = require('sf')]])
      child.lua([[Util = require('sf.util')]])
      child.lua([[Term = require('sf.term')]])
      child.lua([[Md = require('sf.md')]])
      child.lua([[Test = require('sf.test')]])
      child.lua([[Ctags = require('sf.ctags')]])
      child.lua([[Test_sign = require('sf.sub.test_sign')]])
    end,
    post_once = child.stop,
  },
})

T['get_target_org()'] = new_set()

T['get_target_org()']['return target_org'] = function()
  child.lua([[Util.target_org = 'sandbox1']])
  eq(child.lua([[return Sf.get_target_org()]]), 'sandbox1')
end

T['get_target_org()']['throws when empty target_org'] = function()
  expect.error(function() child.lua([[Sf.get_target_org()]]) end)
end

T['covered_percent()'] = new_set()

T['covered_percent()']['return covered_percent'] = function()
  child.lua([[Test_sign.covered_percent = '10']])
  eq(child.lua([[return Sf.covered_percent()]]), '10')
end

T['copy_apex_name()'] = new_set()

T['covered_percent()']['return covered_percent'] = function()
  child.lua([[Test_sign.covered_percent = '10']])
  eq(child.lua([[return Sf.covered_percent()]]), '10')
end

return T
