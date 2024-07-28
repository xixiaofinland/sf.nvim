local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
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

local has_cmd_pattern = function(cmd, pattern) return expect.match(child.cmd_capture(cmd), pattern) end
local has_nmap = function(lhs) return has_cmd_pattern('nmap ' .. lhs, 'Sf') end

local no_cmd_pattern = function(cmd, pattern) return expect.no_match(child.cmd_capture(cmd), pattern) end
local no_nmap = function(lhs) return no_cmd_pattern('nmap ' .. lhs, 'Sf') end

local expect_config = function(field, value) eq(child.lua_get('vim.g.sf.' .. field), value) end

T['get_target_org()'] = new_set()

T['get_target_org()']['return target_org'] = function()
  local value = 'sandbox1'
  local lua_cmd = string.format('Util.target_org = "%s"', value)

  child.lua(lua_cmd)
  eq(child.lua('return Sf.get_target_org()'), value)
end

T['get_target_org()']['throws when empty target_org'] = function()
  local lua_cmd = string.format('Sf.get_target_org()')

  expect.error(function() child.lua(lua_cmd) end)
end

T['covered_percent()'] = new_set()

T['covered_percent()']['return covered_percent from test_sign'] = function()
  local value = "10"
  local lua_cmd = string.format('Test_sign.covered_percent = "%s"', value)

  child.lua(lua_cmd)
  eq(child.lua('return Sf.covered_percent()'), value)
end

T['copy_apex_name()'] = new_set()

T['copy_apex_name()']['return apex name'] = function()
  local apex_name = 'SfProject'
  local lua_cmd = string.format('edit tests/dir/sf-project/%s.cls', apex_name)
  child.cmd(lua_cmd)

  child.type_keys('<leader>cc')

  eq(child.lua_get('vim.bo.filetype'), 'apex')
  eq(child.bo.filetype, 'apex')

  -- TODO: fix
  -- eq(child.lua_get([[vim.fn.getreg("*")]]), apex_name)
  -- eq(child.fn.getreg("*"), apex_name)
end

return T
