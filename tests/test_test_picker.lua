local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.lua([[require('sf.util').target_org = 'myorg']])
      child.capture_notify()
      child.sf_fake.install({ { cmd = "sf apex run test" } })
    end,
    post_once = child.stop,
  },
})

-- Opens a fresh buffer holding test class `class` with the given test methods.
---@param class string
---@param methods string[]
local edit_test_class = function(class, methods)
  local lines = { "@IsTest", "private class " .. class .. " {" }
  for _, m in ipairs(methods) do
    table.insert(lines, "  @IsTest static void " .. m .. "() {}")
  end
  table.insert(lines, "}")
  child.cmd("enew")
  child.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  child.bo.filetype = "apex"
end

local open_picker = function()
  child.lua([[require('sf.test').open()]])
end

-- Back to the class window, leaving the picker open.
local leave_picker = function()
  child.cmd("wincmd p")
end

-- Toggles the picker line of `method` (the picker must be the current window).
local toggle = function(method)
  local lines = child.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:sub(5) == method then
      child.api.nvim_win_set_cursor(0, { i, 0 })
      child.type_keys("x")
      return
    end
  end
  error("not in picker: " .. method)
end

local picker_lines = function()
  return child.api.nvim_buf_get_lines(0, 1, -1, false)
end

-- The sf commands the picker ran, without the echo the terminal prints first.
local run_cmds = function()
  child.sf_fake.wait()
  return vim.tbl_map(function(cmd)
    return cmd:match(";(sf .*)$")
  end, child.sf_fake.cmds())
end

-- The `-t` values of the one sf command the picker ran.
local run_tests = function()
  local cmds = run_cmds()
  eq(#cmds, 1)
  local tests = {}
  for t in cmds[1]:gmatch(" %-t (%S+)") do
    table.insert(tests, t)
  end
  return tests
end

T["selections in one class do not carry over to another class"] = function()
  edit_test_class("ATest", { "a1", "a2" })
  open_picker()
  toggle("a1")
  leave_picker()

  edit_test_class("BTest", { "b1", "b2" })
  open_picker()
  eq(picker_lines(), { "[ ] b1", "[ ] b2" })
  toggle("b2")
  child.type_keys("cc")

  eq(run_tests(), { "BTest.b2" })
end

T["cc runs exactly the selected tests"] = function()
  edit_test_class("ATest", { "a1", "a2", "a3" })
  open_picker()
  toggle("a1")
  toggle("a2")
  toggle("a3")
  toggle("a2")
  eq(picker_lines(), { "[x] a1", "[ ] a2", "[x] a3" })
  child.type_keys("cc")

  eq(run_tests(), { "ATest.a1", "ATest.a3" })
  helpers.expect.no_match(run_cmds()[1], " %-c")
end

T["CC runs exactly the selected tests with code coverage"] = function()
  edit_test_class("ATest", { "a1", "a2" })
  open_picker()
  toggle("a2")
  child.type_keys("CC")

  eq(run_tests(), { "ATest.a2" })
  helpers.expect.match(run_cmds()[1], " %-c ")
end

T["a selected method that is gone from the class when reopened is not run"] = function()
  edit_test_class("ATest", { "a1", "a2" })
  open_picker()
  toggle("a1")
  toggle("a2")
  leave_picker()

  child.api.nvim_buf_set_lines(0, 3, 4, false, {})
  open_picker()
  eq(picker_lines(), { "[x] a1" })
  child.type_keys("cc")

  eq(run_tests(), { "ATest.a1" })
end

T["a test class with no test methods shows a message and opens no picker"] = function()
  edit_test_class("EmptyTest", {})
  open_picker()

  eq(#child.api.nvim_list_wins(), 1)
  eq(child.notified(), { { msg = "No Apex test method in this file.", level = child.lua_get("vim.log.levels.WARN") } })
end

T["a class with no test methods closes the picker left open for another class"] = function()
  edit_test_class("ATest", { "a1" })
  open_picker()
  leave_picker()

  edit_test_class("EmptyTest", {})
  open_picker()

  eq(#child.api.nvim_list_wins(), 1)
end

T["x on the title line leaves the picker read-only"] = function()
  edit_test_class("ATest", { "a1" })
  open_picker()
  child.api.nvim_win_set_cursor(0, { 1, 0 })
  child.type_keys("x")

  eq(child.bo.modifiable, false)
end

---@param n integer
---@return string[]
local numbered_methods = function(n)
  local methods = {}
  for i = 1, n do
    table.insert(methods, "t" .. i)
  end
  return methods
end

T["lists every method of a class with more than 100 tests, also when reopened"] = function()
  local expected = vim.tbl_map(function(m)
    return "[ ] " .. m
  end, numbered_methods(120))

  edit_test_class("BigTest", numbered_methods(120))
  open_picker()
  eq(picker_lines(), expected)

  leave_picker()
  open_picker()
  eq(picker_lines(), expected)
end

T["reopening for a class with fewer methods leaves no stale lines"] = function()
  edit_test_class("ATest", numbered_methods(120))
  open_picker()
  leave_picker()

  edit_test_class("BTest", { "b1" })
  open_picker()

  eq(picker_lines(), { "[ ] b1" })
end

return T
