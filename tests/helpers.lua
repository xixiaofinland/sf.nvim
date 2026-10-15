-- Shared test helpers. Each test file starts with
--
--   local helpers = dofile("tests/helpers.lua")
--   local child = helpers.new_child_neovim()
--
-- and drives the plugin in that child Neovim.
--
-- ── Faking the sf CLI
--
-- Tests never run a real `sf`. `child.sf_fake.install(rules)` replaces
-- `vim.system`, `vim.fn.jobstart`, `vim.fn.termopen` and `vim.fn.jobstop` in the child (code in
-- tests/sf_fake.lua). A rule matches when its `cmd` is a plain substring of
-- the command line (argv tables are joined with spaces); the first match wins
-- and answers with its `stdout`, `stderr` and `code` (default 0), or with a
-- recorded fixture named by `fixture`. Any command no rule matches raises an
-- error naming it, and `vim.fn.executable()` reports the programs the rules
-- name as installed. A rule with `times = n` answers only its first n matches,
-- so a later rule for the same command can answer the rest. A rule with
-- `hold = true` starts a job that keeps running until `vim.fn.jobstop()` (also
-- faked; the job exits 143) or `child.lua("SfFake.exit(job_id, code)")` ends
-- it; `SfFake.running` holds those jobs by id. A rule with `spawn_fails = true`
-- makes `jobstart`/`termopen` return -1.
--
--   child.sf_fake.install({
--     { cmd = "sf org list", fixture = "org_list" },
--     { cmd = "sf config set target-org" },
--   })
--   child.lua([[require('sf').fetch_org_list()]])
--   child.sf_fake.wait()
--   eq(child.sf_fake.cmds(), { "sf org list --json --skip-connection-status" })
--
-- Callbacks are delivered on a later event-loop tick, as real processes do;
-- `child.sf_fake.wait()` returns once they, and anything they scheduled, have
-- run. Pass `{ mode = "sync" }` as the second argument to `install()` to run
-- them before the faked call returns instead.
--
-- ── Recording a fixture
--
-- Fixtures live in tests/fixtures/sf/<name>.lua and return
-- `{ recorded = bool, code = int, stdout = string, stderr = string|nil }`.
-- To record one:
--   1. Run the command against a throwaway org, e.g.
--      `sf org list --json --skip-connection-status > out.json`; note its exit code.
--   2. Scrub it: replace access tokens, usernames, org/user/record ids, instance
--      URLs and names with fake values like those in the existing fixtures.
--   3. Paste it into the `stdout` long string, update the header comment with
--      the command and sf CLI version (`sf --version`), and set `recorded = true`.
-- Fixtures with `recorded = false` are synthetic, shaped after the sf CLI's
-- source; their header names the source so they can be swapped for captures.

local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.expect.match = MiniTest.new_expectation("string matching", function(str, pattern)
  return str:find(pattern) ~= nil
end, function(str, pattern)
  return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
end)

Helpers.expect.no_match = MiniTest.new_expectation("no string matching", function(str, pattern)
  return str:find(pattern) == nil
end, function(str, pattern)
  return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
end)

Helpers.expect.ends_with = MiniTest.new_expectation("string ending", function(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end, function(str, ending)
  return string.format("Ending: %s\nObserved string: %s", vim.inspect(ending), str)
end)

local root = vim.fn.getcwd()

---@param name string File name in tests/fixtures/sf/, without ".lua"
---@return { recorded: boolean, code: integer, stdout: string, stderr: string|nil }
Helpers.sf_fixture = function(name)
  return dofile(string.format("%s/tests/fixtures/sf/%s.lua", root, name))
end

Helpers.new_child_neovim = function()
  local child = MiniTest.new_child_neovim()
  local eq = Helpers.expect.equality

  child.setup = function()
    child.restart({ "-u", "scripts/minimal_init.lua" })
    child.bo.readonly = false
  end

  child.sf_setup = function(config)
    local req_cmd = [[require('sf').setup(...)]]
    child.lua(req_cmd, { config })
  end

  child.open_in_sf_dir = function(file, project)
    project = project or "sf-project"
    local lua_cmd = string.format("edit tests/dir/%s/%s", project, file)
    child.cmd(lua_cmd)
  end

  child.go_to_sf_dir = function()
    child.cmd("cd tests/dir/sf-project/")
  end

  child.go_to_non_sf_dir = function()
    child.cmd("cd tests/dir/non-sf-project/")
  end

  child.go_to_sf_sub_dir = function()
    child.cmd("cd tests/dir/sf-project/sf_cache/")
  end

  child.open_in_non_sf_dir = function(file)
    local lua_cmd = string.format("edit tests/dir/non-sf-project/%s", file)
    child.cmd(lua_cmd)
  end

  -- ── Assertions on the child's state

  child.has_cmd_pattern = function(cmd, pattern)
    return Helpers.expect.match(child.cmd_capture(cmd), pattern)
  end

  child.no_cmd_pattern = function(cmd, pattern)
    return Helpers.expect.no_match(child.cmd_capture(cmd), pattern)
  end

  child.has_nmap = function(lhs)
    return child.has_cmd_pattern("nmap " .. lhs, "Sf")
  end

  child.no_nmap = function(lhs)
    return child.no_cmd_pattern("nmap " .. lhs, "Sf")
  end

  child.expect_config = function(field, value)
    eq(child.lua_get("vim.g.sf." .. field), value)
  end

  -- ── Stubs for Neovim's UI hooks

  -- Records every notification instead of showing it; read them with `notified()`.
  child.capture_notify = function()
    child.lua([[
      _G.notified = {}
      vim.notify = function(msg, level) table.insert(_G.notified, { msg = msg, level = level }) end
      vim.notify_once = vim.notify
    ]])
  end

  ---@return { msg: string, level: integer|nil }[]
  child.notified = function()
    return child.lua_get("_G.notified")
  end

  -- Replaces `vim.ui.select` with one that picks `choice` (nil cancels) and
  -- records each call; read them with `select_calls()`.
  ---@param choice string|nil
  child.stub_select = function(choice)
    child.lua(
      [[
      local choice = ...
      _G.select_calls = {}
      vim.ui.select = function(items, opts, on_choice)
        table.insert(_G.select_calls, { items = items, prompt = opts.prompt })
        on_choice(choice)
      end
    ]],
      { choice }
    )
  end

  ---@return { items: string[], prompt: string }[]
  child.select_calls = function()
    return child.lua_get("_G.select_calls")
  end

  -- ── Fake sf CLI (see the notes at the top of this file)

  child.sf_fake = {}

  ---@param rules { cmd: string, times: integer|nil, fixture: string|nil, stdout: string|nil, stderr: string|nil, code: integer|nil, hold: boolean|nil, spawn_fails: boolean|nil }[]
  ---@param opts { mode: "schedule"|"sync"|nil }|nil
  child.sf_fake.install = function(rules, opts)
    local resolved = {}
    for _, rule in ipairs(rules) do
      local r = rule.fixture and vim.tbl_extend("force", Helpers.sf_fixture(rule.fixture), rule) or vim.deepcopy(rule)
      -- Only the response fields matter to the child
      r.fixture, r.recorded = nil, nil
      table.insert(resolved, r)
    end
    child.lua("_G.SfFake = dofile(...)", { root .. "/tests/sf_fake.lua" })
    child.lua("SfFake.install(...)", { resolved, opts or vim.empty_dict() })
  end

  ---@return { cmd: string, argv: string[]|nil, via: "system"|"jobstart"|"termopen", stdin: string|nil }[]
  child.sf_fake.calls = function()
    return child.lua_get("SfFake.calls")
  end

  ---@return string[]
  child.sf_fake.cmds = function()
    return child.lua_get("vim.tbl_map(function(c) return c.cmd end, SfFake.calls)")
  end

  ---@param timeout integer|nil Milliseconds, 1000 by default
  child.sf_fake.wait = function(timeout)
    child.lua("SfFake.wait(...)", { timeout })
  end

  return child
end

return Helpers
