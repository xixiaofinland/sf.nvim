local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local new_set = MiniTest.new_set

-- helper

local mock_test = function()
  child.cmd('luafile tests/dir-org/mock.lua')
end

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[M = require('sf.org')]])
      child.lua([[S = require('sf')]])
    end,
    post_once = child.stop,
  },
})

T['fetch_org_list()'] = new_set({ hooks = { pre_case = mock_test } })

T['fetch_org_list()']['test1'] = function()
  eq(child.lua_get([[vim.lsp.buf_get_clients()]]), {'mock client'})
end
--
-- T['get()']['target_org empty then err'] = function()
--   expect.error(function() child.lua([[M.get()]]) end)
-- end

return T
