local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.open_in_sf_dir("test.txt")
      child.lua([[Sf = require('sf')]])
    end,
    post_once = child.stop,
  },
})

local fetch_orgs = function()
  child.lua([[Sf.fetch_org_list()]])
  child.sf_fake.wait()
end

T["fetch_org_list()"] = new_set()

T["fetch_org_list()"]["runs sf org list and takes the default org as target_org"] = function()
  child.sf_fake.install({ { cmd = "sf org list", fixture = "org_list" } })

  fetch_orgs()

  eq(child.sf_fake.cmds(), { "sf org list --json --skip-connection-status" })
  eq(child.lua_get([[Sf.get_target_org()]]), "devhub")
end

T["set_target_org()"] = new_set()

T["set_target_org()"]["offers the fetched orgs and sets the chosen one as target_org"] = function()
  child.sf_fake.install({
    { cmd = "sf org list", fixture = "org_list" },
    { cmd = "sf config set target-org" },
  })
  fetch_orgs()
  child.stub_select("[S] my-scratch")

  child.lua([[Sf.set_target_org()]])
  child.sf_fake.wait()

  -- Non-scratch orgs first, scratch orgs marked; an org without an alias is
  -- listed by username.
  eq(child.select_calls(), {
    { prompt = "Local target_org:", items = { "devhub", "uat", "admin@other.example.com", "[S] my-scratch" } },
  })
  eq(child.sf_fake.cmds(), {
    "sf org list --json --skip-connection-status",
    'sf config set target-org "my-scratch"',
  })
  eq(child.lua_get([[Sf.get_target_org()]]), "my-scratch")
end

T["set_target_org()"]["keeps target_org when sf config set fails"] = function()
  child.sf_fake.install({
    { cmd = "sf org list", fixture = "org_list" },
    { cmd = "sf config set target-org", code = 1, stderr = "Error (1): fake failure" },
  })
  fetch_orgs()
  child.stub_select("uat")
  child.capture_notify()

  child.lua([[Sf.set_target_org()]])
  child.sf_fake.wait()

  eq(child.lua_get([[Sf.get_target_org()]]), "devhub")
  eq(child.notified(), {
    {
      msg = "uat - set target_org failed! Not in a sfdx project folder?",
      level = child.lua_get("vim.log.levels.ERROR"),
    },
  })
end

T["set_global_target_org()"] = new_set()

T["set_global_target_org()"]["does not open selector when org list is empty"] = function()
  child.stub_select(nil)
  child.capture_notify()

  child.lua([[Sf.set_global_target_org()]])

  eq(child.select_calls(), {})
  eq(child.notified(), {
    { msg = "No orgs available. Run :SF org list first.", level = child.lua_get("vim.log.levels.ERROR") },
  })
end

T["sf fake"] = new_set()

T["sf fake"]["errors on a command no rule matches"] = function()
  child.sf_fake.install({})

  local ok, err = pcall(child.lua, [[vim.system({ "sf", "org", "list" })]])

  eq(ok, false)
  helpers.expect.match(err, "no rule matches command: sf org list")
end

T["sf fake"]["wait() reports a command no rule matched in a scheduled callback"] = function()
  child.sf_fake.install({})
  child.lua([[vim.schedule(function() vim.fn.jobstart("sf org open") end)]])

  local ok, err = pcall(child.sf_fake.wait)

  eq(ok, false)
  helpers.expect.match(err, "no rule matches command: sf org open")
end

T["sf fake"]["answers vim.system, jobstart and termopen with the rule's output"] = function()
  child.sf_fake.install(
    { { cmd = "sf version", stdout = "line1\nline2", stderr = "warn", code = 3 } },
    { mode = "sync" }
  )

  local system = child.lua_get([[vim.system({ "sf", "version" }, { stdin = "in" }):wait()]])
  eq({ system.code, system.stdout, system.stderr }, { 3, "line1\nline2", "warn" })

  local job = child.lua_get([[(function()
    local got = {}
    vim.fn.jobstart("sf version", {
      on_stdout = function(_, data) got.stdout = data end,
      on_stderr = function(_, data) got.stderr = data end,
      on_exit = function(_, code) got.code = code end,
    })
    return got
  end)()]])
  eq(job, { stdout = { "line1", "line2" }, stderr = { "warn" }, code = 3 })

  child.lua([[vim.fn.termopen("sf version", {})]])
  eq(child.api.nvim_buf_get_lines(0, 0, -1, false), { "line1", "line2" })

  eq(child.sf_fake.calls(), {
    { cmd = "sf version", argv = { "sf", "version" }, via = "system", stdin = "in" },
    { cmd = "sf version", via = "jobstart" },
    { cmd = "sf version", via = "termopen" },
  })
  eq(child.fn.executable("sf"), 1)
end

return T
