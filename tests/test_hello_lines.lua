-- Define helper aliases
local new_set = MiniTest.new_set
local expect, eq = MiniTest.expect, MiniTest.expect.equality

-- Create (but not start) child Neovim object
local child = MiniTest.new_child_neovim()

-- Define main test set of this file
local T = new_set({
  -- Register hooks
  hooks = {
    -- This will be executed before every (even nested) case
    pre_case = function()
      -- Restart child process with custom 'init.lua' script
      child.restart({ '-u', 'scripts/minimal_init.lua' })
      -- Load tested plugin
      child.lua([[M = require('sf')]])
    end,
    -- This will be executed one after all tests from this set are finished
    post_once = child.stop,
  },
})

-- Test set fields define nested structure
T['compute()'] = new_set()

-- Define test action as callable field of test set.
-- If it produces error - test fails.
T['compute()']['works'] = function()
  -- Execute Lua code inside child process, get its result and compare with
  -- expected result
  eq(child.lua_get([[M.compute({'a', 'b'})]]), { 'Hello a', 'Hello b' })
end

-- T['compute()']['uses correct defaults'] = function()
--   eq(child.lua_get([[M.compute()]]), { 'Hello world' })
-- end
--
-- -- Make parametrized tests. This will create three copies of each case
-- T['set_lines()'] = new_set({ parametrize = { {}, { 0, { 'a' } }, { 0, { 1, 2, 3 } } } })
--
-- -- Use arguments from test parametrization
-- T['set_lines()']['works'] = function(buf_id, lines)
--   -- Directly modify some options to make better test
--   child.o.lines, child.o.columns = 10, 20
--   child.bo.readonly = false
--
--   -- Execute Lua code without returning value
--   child.lua('M.set_lines(...)', { buf_id, lines })
--
--   -- Test screen state. On first run it will automatically create reference
--   -- screenshots with text and look information in predefined location. On
--   -- later runs it will compare current screenshot with reference. Will throw
--   -- informative error with helpful information if they don't match exactly.
--   expect.reference_screenshot(child.get_screenshot())
-- end
--
-- -- Return test set which will be collected and execute inside `MiniTest.run()`
return T
