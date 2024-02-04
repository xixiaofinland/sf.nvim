local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- local child = MiniTest.new_child_neovim()

local T = new_set()

-- local T = new_set({
--   hooks = {
--     pre_case = function()
--       child.restart({ '-u', 'scripts/minimal_init.lua' })
--       child.lua([[M = require('sf')]])
--     end,
--
--     post_once = child.stop,
--   },
-- })

T['error'] = function()
  -- it should throw as `target_org` defaults to empty
  expect.error(function()
    M.get()
  end)
end

return T
