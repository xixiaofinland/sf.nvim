local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local new_set = MiniTest.new_set

-- A throwaway sf project whose path has a space, holding SfProject.cls (15
-- lines, the class the coverage fixture covers) and its test class.
local project

local coverage_json = function()
  return vim.json.decode(helpers.sf_fixture("apex_get_test_coverage").stdout)
end

local class_path = function(name)
  return project .. "/force-app/main/default/classes/" .. name
end

local result_path = function()
  return project .. "/sf_cache/test_result.json"
end

---@param json table|nil `sf apex get test -c --json` output; the fixture's by default
local save_result = function(json)
  vim.fn.mkdir(project .. "/sf_cache", "p")
  vim.fn.writefile({ vim.json.encode(json or coverage_json()) }, result_path())
end

local read_result = function()
  return vim.json.decode(table.concat(vim.fn.readfile(result_path()), "\n"))
end

-- The fixture's result with SfProject's uncovered lines replaced by `uncovered`.
---@param uncovered integer[]
local result_with_uncovered = function(uncovered)
  local json = coverage_json()
  local lines = {}
  for _, l in ipairs(uncovered) do
    lines[tostring(l)] = 0
  end
  json.result.coverage.coverage[1].lines = lines
  return json
end

-- Starts the plugin as Neovim opened in the project: signs are only enabled
-- at setup inside one.
local setup = function(config)
  child.cmd("cd " .. vim.fn.fnameescape(project))
  child.sf_setup(config)
  child.lua([[Sf = require('sf')]])
  child.lua([[require('sf.util').target_org = 'myorg']])
  child.capture_notify()
end

local edit = function(name)
  child.cmd("edit " .. vim.fn.fnameescape(class_path(name)))
end

---@return { name: string, lnum: integer, group: string }[]
local signs = function()
  return child.lua_get([[vim.tbl_map(function(s)
    return { name = s.name, lnum = s.lnum, group = s.group }
  end, vim.fn.sign_getplaced(vim.api.nvim_get_current_buf(), { group = "*" })[1].signs)]])
end

local errors = function()
  return vim.tbl_filter(function(n)
    return n.level == child.lua_get("vim.log.levels.ERROR")
  end, child.notified())
end

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      project = vim.fn.tempname() .. " my project"
      vim.fn.mkdir(project .. "/force-app/main/default/classes", "p")
      vim.fn.writefile(
        { '{ "packageDirectories": [{ "path": "force-app", "default": true }] }' },
        project .. "/sfdx-project.json"
      )
      local class = { "public class SfProject {" }
      for i = 2, 14 do
        table.insert(class, "  // line " .. i)
      end
      table.insert(class, "}")
      vim.fn.writefile(class, class_path("SfProject.cls"))
      vim.fn.writefile({
        "@IsTest",
        "private class SfProjectTest {",
        "  @IsTest static void constructsWithName() {}",
        "}",
      }, class_path("SfProjectTest.cls"))
    end,
    post_case = function()
      vim.fn.delete(project, "rf")
    end,
    post_once = child.stop,
  },
})

T["signs"] = new_set()

T["signs"]["opening a class before any coverage run says nothing"] = function()
  setup()

  edit("SfProject.cls")

  eq(child.notified(), {})
  eq(signs(), {})
end

T["signs"]["with covered signs hidden, only uncovered lines get signs"] = function()
  save_result()
  setup({ code_sign_highlight = { covered = { fg = "" } } })

  edit("SfProject.cls")

  eq(signs(), {
    { name = "sf_uncovered", lnum = 12, group = "SfUncovered" },
    { name = "sf_uncovered", lnum = 13, group = "SfUncovered" },
  })
  eq(errors(), {})
  eq(child.v.errmsg, "")
end

T["signs"]["show covered and uncovered lines"] = function()
  save_result()
  setup()

  edit("SfProject.cls")

  eq(signs(), {
    { name = "sf_covered", lnum = 4, group = "SfCovered" },
    { name = "sf_covered", lnum = 5, group = "SfCovered" },
    { name = "sf_covered", lnum = 8, group = "SfCovered" },
    { name = "sf_covered", lnum = 9, group = "SfCovered" },
    { name = "sf_uncovered", lnum = 12, group = "SfUncovered" },
    { name = "sf_uncovered", lnum = 13, group = "SfUncovered" },
  })
end

T["signs"]["covered percent of the current file comes from the result"] = function()
  save_result()
  setup()

  edit("SfProject.cls")

  eq(child.lua_get("Sf.covered_percent()"), 67)
end

T["jump"] = new_set()

T["jump"]["without uncovered signs does nothing"] = function()
  save_result()
  setup()
  -- SfProject.cls has an uncovered sign, the current buffer none
  edit("SfProject.cls")
  edit("SfProjectTest.cls")
  child.api.nvim_win_set_cursor(0, { 2, 0 })

  child.lua("Sf.uncovered_jump_forward()")
  child.lua("Sf.uncovered_jump_backward()")

  helpers.expect.ends_with(child.api.nvim_buf_get_name(0), "/SfProjectTest.cls")
  eq(child.api.nvim_win_get_cursor(0), { 2, 0 })
  eq(child.v.errmsg, "")
end

-- Uncovered lines 3-4, 8 and 12 make hunks starting at 3, 8 and 12.
local jumps = {
  { uncovered = { 3, 4, 8, 12 }, from = 1, forward = 3, backward = 12 },
  { uncovered = { 3, 4, 8, 12 }, from = 3, forward = 8, backward = 12 },
  { uncovered = { 3, 4, 8, 12 }, from = 4, forward = 8, backward = 3 },
  { uncovered = { 3, 4, 8, 12 }, from = 5, forward = 8, backward = 3 },
  { uncovered = { 3, 4, 8, 12 }, from = 8, forward = 12, backward = 3 },
  { uncovered = { 3, 4, 8, 12 }, from = 12, forward = 3, backward = 8 },
  { uncovered = { 3, 4, 8, 12 }, from = 15, forward = 3, backward = 12 },
  { uncovered = { 6 }, from = 6, forward = 6, backward = 6 },
  { uncovered = { 6 }, from = 2, forward = 6, backward = 6 },
}

for _, case in ipairs(jumps) do
  local name = string.format("uncovered %s, from line %d", table.concat(case.uncovered, ","), case.from)
  T["jump"][name] = function()
    save_result(result_with_uncovered(case.uncovered))
    setup()
    edit("SfProject.cls")

    child.api.nvim_win_set_cursor(0, { case.from, 0 })
    child.lua("Sf.uncovered_jump_forward()")
    eq(child.api.nvim_win_get_cursor(0)[1], case.forward)

    child.api.nvim_win_set_cursor(0, { case.from, 0 })
    child.lua("Sf.uncovered_jump_backward()")
    eq(child.api.nvim_win_get_cursor(0)[1], case.backward)
  end
end

T["saving"] = new_set()

local run_with_coverage = function(get_test_rule)
  child.sf_fake.install({
    { cmd = "sf apex run test", fixture = "apex_run_test_human" },
    get_test_rule,
  })
  edit("SfProjectTest.cls")
  child.lua("Sf.run_all_tests_in_this_file_with_coverage()")
  child.sf_fake.wait()
end

T["saving"]["writes the result under a project path with spaces and places signs"] = function()
  setup()
  edit("SfProject.cls")

  run_with_coverage({ cmd = "sf apex get test", fixture = "apex_get_test_coverage" })

  eq(read_result(), coverage_json())
  local get_test = child.sf_fake.calls()[2]
  local run_id = helpers.sf_fixture("apex_run_test_human").stdout:match("Test Run Id%s+(%w+)")
  eq(get_test.argv, { "sf", "apex", "get", "test", "-i", run_id, "--json", "-c", "-o", "myorg" })
  eq(child.notified(), { { msg = "Code coverage saved.", level = child.lua_get("vim.log.levels.INFO") } })

  edit("SfProject.cls")
  eq(#signs(), 6)
end

T["saving"]["a failed get test keeps the previous result"] = function()
  local previous = result_with_uncovered({ 2 })
  save_result(previous)
  setup()

  run_with_coverage({ cmd = "sf apex get test", fixture = "apex_get_test_error" })

  eq(read_result(), previous)
  eq(#errors(), 1)
  helpers.expect.match(errors()[1].msg, "Code coverage save failed")

  edit("SfProject.cls")
  eq(signs(), { { name = "sf_uncovered", lnum = 2, group = "SfUncovered" } })
end

return T
