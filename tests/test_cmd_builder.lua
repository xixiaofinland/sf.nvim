local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.lua([[B = require('sf.sub.cmd_builder')]])
      child.lua([[U = require('sf.util')]])
      child.lua('U.target_org = "t_org"')
    end,
    post_once = child.stop,
  },
})

T['setup()'] = new_set()

T['setup()']['can set root command in new()'] = function()
  local result = child.lua_get('B:new("root"):cmd("org"):act("create shape"):build()')
  local expected = 'root org create shape -o "t_org"'
  eq(result, expected)
end

T['setup()']['when both "cmd, act" are given then command building success'] = function()
  local result = child.lua_get('B:new():cmd("org"):act("create shape"):build()')
  local expected = 'sf org create shape -o "t_org"'
  eq(result, expected)
end

T['setup()']['when no "command" property then should throw'] = function()
  expect.error(function() child.lua([[B:new():act("create shape"):build()]]) end)
end

T['setup()']['when no "action" property then should throw'] = function()
  expect.error(function() child.lua([[B:new():cmd("apex"):build()]]) end)
end

T['setup()']['can supply flag:value string in addParams()'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):addParams("-f", "/path/"):build()')
  local expected = 'sf apex run -f "/path/" -o "t_org"'
  eq(result, expected)
end

T['setup()']['can supply flag:value string in more than one addParams()'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):addParams("-f", "/path/"):addParams("-c", "cc"):build()')
  local expected = 'sf apex run -c "cc" -f "/path/" -o "t_org"'
  eq(result, expected)
end

T['setup()']['when supply number param value it turns into string type in cmd'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):addParams("-c", 5):build()')
  local expected = 'sf apex run -c "5" -o "t_org"'
  eq(result, expected)
end

T['setup()']['can supply table {flag = value} in addParams()'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):addParams({["-f"] = "/path/"}):build()')
  local expected = 'sf apex run -f "/path/" -o "t_org"'
  eq(result, expected)
end

T['setup()']['can supply mutliple params in table in addParams()'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):addParams({["-c"] = "test", ["-f"] = "/path/"}):build()')
  local expected = 'sf apex run -c "test" -f "/path/" -o "t_org"'
  eq(result, expected)
end

T['setup()']['can sort params with value alphabetically'] = function()
  local result = child.lua_get(
    'B:new():cmd("apex"):act("run"):addParams({["-f"] = "/path/", ["-c"] = "test", ["-t"] = "" }):build()')
  local expected = 'sf apex run -c "test" -f "/path/" -t -o "t_org"'
  eq(result, expected)
end

T['setup()']['params without value are put to the end of built command'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):addParams({["-z"] = "", ["-c"] = "test"}):build()')
  local expected = 'sf apex run -c "test" -z -o "t_org"'
  eq(result, expected)
end

T['setup()']['sorted params with value, then sorted params without value'] = function()
  local result = child.lua_get(
    'B:new():cmd("apex"):act("run"):addParams({["-f"] = "/path/", ["-c"] = "test", ["-z"] = "", ["-t"] = "" }):build()')
  local expected = 'sf apex run -c "test" -f "/path/" -t -z -o "t_org"'
  eq(result, expected)
end

T['setup()']['can overwrite with new org value'] = function()
  local result = child.lua_get(
    'B:new():cmd("apex"):act("run"):set_org("new_org"):build()')
  local expected = 'sf apex run -o "new_org"'
  eq(result, expected)
end

T['setup()']['throws when no default_org nor set_org() called'] = function()
  child.lua('U.target_org = nil')
  expect.error(function() child.lua([[B:new():cmd("apex"):act("run"):build()]]) end)
end

T['setup()']['when no "org" property then use the default targe"t_org"'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):build()')
  local expected = 'sf apex run -o "t_org"'
  eq(result, expected)
end

T['setup()']['%:p for file_path in param value is expanded'] = function()
  child.open_in_sf_dir('test.txt')
  local file_path = child.lua_get('vim.fn.expandcmd("%:p")')
  local result = child.lua_get([[B:new():cmd("apex"):act("run"):addParams("-f", '%:p'):build()]])
  local expected = string.format('sf apex run -f "%s" -o "t_org"', file_path)
  eq(result, expected)
end

T['setup()']['param_str are attached preceding org'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):addParamStr("-b bb"):addParams("-c"):build()')
  local expected = 'sf apex run -c -b bb -o "t_org"'

  eq(result, expected)
end

T['setup()']['org name with space is safely supported'] = function()
  local result = child.lua_get('B:new():cmd("apex"):act("run"):set_org("target org"):build()')
  local expected = 'sf apex run -o "target org"'

  eq(result, expected)
end

return T
