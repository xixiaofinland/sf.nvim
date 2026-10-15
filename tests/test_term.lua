local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.lua([[Term = require('sf.term')]])
      child.capture_notify()
      -- Records each callback call; read them with `cb_calls()`.
      child.lua([[
        _G.cb_calls = {}
        _G.record_cb = function(name)
          return function(_, _, exit_code)
            table.insert(_G.cb_calls, { name = name, exit_code = exit_code })
          end
        end
      ]])
    end,
    post_once = child.stop,
  },
})

local cb_calls = function()
  return child.lua_get("_G.cb_calls")
end

---@param cmd string
---@param cb_name string|nil
local run = function(cmd, cb_name)
  if cb_name then
    child.lua("Term.run(..., record_cb(select(2, ...)))", { cmd, cb_name })
  else
    child.lua("Term.run(...)", { cmd })
  end
end

local levels = function()
  return child.lua_get("vim.log.levels")
end

T["run()"] = new_set()

T["run()"]["refuses a run while one is busy, with a message"] = function()
  child.sf_fake.install({ { cmd = "sf apex run test", hold = true } })

  run("sf apex run test -n A")
  run("sf apex run test -n B")

  eq(#child.sf_fake.calls(), 1)
  eq(child.notified(), { { msg = "Wait the current task to finish.", level = levels().WARN } })
end

for _, case in ipairs({ { "exit 0", 0 }, { "a non-zero exit", 1 } }) do
  T["run()"]["is idle again after " .. case[1] .. ", and the callback gets the exit code"] = function()
    child.sf_fake.install({ { cmd = "sf apex run test", code = case[2] } })

    run("sf apex run test -n A", "A")
    child.sf_fake.wait()
    run("sf apex run test -n B")
    child.sf_fake.wait()

    eq(#child.sf_fake.calls(), 2)
    eq(cb_calls(), { { name = "A", exit_code = case[2] } })
  end
end

T["run()"]["is idle again after a callback that throws, and reports the error"] = function()
  child.sf_fake.install({ { cmd = "sf apex run test" } })

  child.lua([[Term.run("sf apex run test -n A", function() error("boom") end)]])
  child.sf_fake.wait()
  run("sf apex run test -n B")
  child.sf_fake.wait()

  eq(#child.sf_fake.calls(), 2)
  local notified = child.notified()
  eq(#notified, 1)
  eq(notified[1].level, levels().ERROR)
  helpers.expect.match(notified[1].msg, "boom")
end

T["run()"]["is idle with an error message when the terminal job fails to start"] = function()
  child.sf_fake.install({
    { cmd = "sf apex run test -n A", spawn_fails = true },
    { cmd = "sf apex run test -n B" },
  })

  run("sf apex run test -n A", "A")
  child.sf_fake.wait()

  eq(#child.notified(), 1)
  eq(child.notified()[1].level, levels().ERROR)
  eq(cb_calls(), {})

  run("sf apex run test -n B")
  child.sf_fake.wait()
  eq(#child.sf_fake.calls(), 2)
end

T["cancel()"] = new_set()

T["cancel()"]["stops the running job"] = function()
  child.sf_fake.install({ { cmd = "sf apex run test", hold = true } })

  run("sf apex run test -n A", "A")
  child.lua("Term.cancel()")
  child.sf_fake.wait()

  eq(child.lua_get("vim.tbl_count(SfFake.running)"), 0)
  -- Nothing but the job itself ran: cancelling doesn't start a command of its own.
  eq(#child.sf_fake.calls(), 1)
  -- A cancelled run doesn't fire its callback.
  eq(cb_calls(), {})
end

T["cancel()"]["lets a new run start right away"] = function()
  child.sf_fake.install({ { cmd = "sf apex run test", hold = true } })

  run("sf apex run test -n A")
  child.lua("Term.cancel()")
  run("sf apex run test -n B")

  eq(#child.sf_fake.calls(), 2)
  eq(child.notified(), {})
end

T["cancel()"]["an old job's exit leaves the newer run busy and its callback unfired"] = function()
  child.sf_fake.install({ { cmd = "sf apex run test", hold = true } })

  run("sf apex run test -n A", "A")
  child.lua("Term.cancel()")
  run("sf apex run test -n B", "B")
  -- A's exit from the cancel arrives while B is running.
  child.sf_fake.wait()

  eq(cb_calls(), {})
  run("sf apex run test -n C")
  eq(#child.sf_fake.calls(), 2)
  eq(child.notified(), { { msg = "Wait the current task to finish.", level = levels().WARN } })

  -- B is the only job still running.
  eq(child.lua_get("vim.tbl_count(SfFake.running)"), 1)
  child.lua("SfFake.exit(next(SfFake.running), 3)")
  child.sf_fake.wait()
  eq(cb_calls(), { { name = "B", exit_code = 3 } })
end

T["cancel()"]["says so when nothing is running"] = function()
  child.sf_fake.install({})

  child.lua("Term.cancel()")

  eq(child.sf_fake.calls(), {})
  eq(child.notified(), { { msg = "No running task to cancel.", level = levels().INFO } })
end

-- ── Shell metacharacters
--
-- The fake terminal records the command line; these tests then run it through
-- a real shell with a stub `sf` that prints its arguments and stdin, to see
-- what the shell made of it. The stub is plain sh, so this never reaches a
-- real sf.

local stub_dir = vim.fn.tempname()
vim.fn.mkdir(stub_dir, "p")
local marker = stub_dir .. "/expanded"
vim.fn.writefile({
  "#!/bin/sh",
  [[for a in "$@"; do printf 'arg:%s\n' "$a"; done]],
  [[printf 'stdin:'; cat]],
}, stub_dir .. "/sf")
vim.fn.setfperm(stub_dir .. "/sf", "rwxr-xr-x")

-- None of these may run or change: a command substitution that would leave a
-- marker file, a variable, backticks, a double quote and backslashes (fish
-- reads `\\` and `\'` even inside single quotes).
local nasty = string.format([[$(touch %s) $HOME `touch %s` " \ \n \\ \']], marker, marker)

local ESC = string.char(27)

---@param shell string
local run_in_shell = function(shell)
  local term_cmd = child.sf_fake.calls()[1].cmd
  local out = child.lua_get(
    [[(function(shell, cmd, dir)
      vim.o.shell = shell
      local path = vim.env.PATH
      vim.env.PATH = dir .. ":" .. path
      local out = vim.fn.system(cmd, "")
      vim.env.PATH = path
      return out
    end)(...)]],
    { shell, term_cmd, stub_dir }
  )
  -- The banner spans several lines when the command does; the stub's output
  -- starts at its first argument.
  local split = assert(out:find("\narg:", 1, true), out)
  return {
    term_cmd = term_cmd,
    -- With its color codes and padding taken off
    banner = vim.trim((out:sub(1, split - 1):gsub(ESC .. "%[[%d;]*m", ""))),
    rest = out:sub(split + 1),
  }
end

---@param result { term_cmd: string, banner: string }
local expect_banner_shows_command = function(result)
  -- The banner shows exactly the command that runs after it.
  helpers.expect.ends_with(result.term_cmd, result.banner)
  helpers.expect.match(result.banner, "sf ")
end

T["shell metacharacters"] = new_set({
  parametrize = { { "sh" }, { "bash" }, { "zsh" }, { "fish" } },
  hooks = {
    pre_case = function()
      vim.fn.delete(marker)
      child.lua([[require('sf.util').target_org = "t_org"]])
    end,
  },
})

T["shell metacharacters"]["anonymous Apex reaches sf unchanged"] = function(shell)
  if vim.fn.executable(shell) == 0 then
    MiniTest.skip(shell .. " is not installed")
  end
  child.o.shell = shell
  child.sf_fake.install({ { cmd = "sf apex run" } })
  local apex = { "System.debug('" .. nasty .. "');", "Integer i = 1;" }
  child.api.nvim_buf_set_lines(0, 0, -1, false, apex)

  child.lua("Term.run_anonymous_stdin(false)")

  local result = run_in_shell(shell)
  expect_banner_shows_command(result)
  eq(result.rest, "arg:apex\narg:run\narg:-o\narg:t_org\nstdin:" .. table.concat(apex, "\n") .. "\n")
  eq(vim.fn.filereadable(marker), 0)
end

T["shell metacharacters"]["highlighted SOQL reaches sf unchanged"] = function(shell)
  if vim.fn.executable(shell) == 0 then
    MiniTest.skip(shell .. " is not installed")
  end
  child.o.shell = shell
  child.sf_fake.install({ { cmd = "sf data query" } })
  local soql = "SELECT Id FROM Account WHERE Name = '" .. nasty .. "'"
  child.api.nvim_buf_set_lines(0, 0, -1, false, { soql })
  child.type_keys("0vg_")

  child.lua("Term.run_highlighted_soql()")

  local result = run_in_shell(shell)
  expect_banner_shows_command(result)
  eq(result.rest, "arg:data\narg:query\narg:-q\narg:" .. soql .. "\narg:-o\narg:t_org\nstdin:")
  eq(vim.fn.filereadable(marker), 0)
end

return T
