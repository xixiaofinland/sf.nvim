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

-- Only errors: a sandboxed child also warns that its log file isn't writable
local notified_errors = function()
  return child.lua_get([[vim.tbl_map(
    function(n) return n.msg end,
    vim.tbl_filter(function(n) return n.level == vim.log.levels.ERROR end, _G.notified)
  )]])
end

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

T["fetch_org_list()"]["lists each org once when refreshed twice quickly"] = function()
  child.sf_fake.install({ { cmd = "sf org list", fixture = "org_list" } })

  child.lua([[Sf.fetch_org_list(); Sf.fetch_org_list()]])
  child.sf_fake.wait()
  child.stub_select(nil)
  child.lua([[Sf.set_target_org()]])

  eq(child.select_calls()[1].items, { "devhub", "uat", "admin@other.example.com", "[S] my-scratch" })
end

T["fetch_org_list()"]["clears target_org when the refreshed list has no default org"] = function()
  child.sf_fake.install({
    { cmd = "sf org list", fixture = "org_list", times = 1 },
    {
      cmd = "sf org list",
      stdout = [[{"status":0,"result":{"nonScratchOrgs":[{"alias":"uat","username":"u@x.com"}],"scratchOrgs":[]}}]],
    },
  })
  fetch_orgs()
  eq(child.lua_get([[Sf.get_target_org()]]), "devhub")

  fetch_orgs()

  eq(child.lua_get([[require('sf.util').target_org]]), "")
end

T["fetch_org_list()"]["shows an error when sf fails"] = function()
  child.sf_fake.install({ { cmd = "sf org list", code = 1, stderr = "Error (1): fake failure" } })
  child.capture_notify()

  fetch_orgs()

  eq(notified_errors(), { "Failed to list orgs: Error (1): fake failure" })
end

T["fetch_org_list()"]["shows an error when sf prints something other than JSON"] = function()
  child.sf_fake.install({ { cmd = "sf org list", stdout = "Warning: a new sf version is available" } })
  child.capture_notify()

  fetch_orgs()

  eq(notified_errors(), { "Failed to list orgs: sf output is not JSON" })
end

T["diff_in_org()"] = new_set()

-- Each case fails the retrieve: the command line is what's under test.
local diff_in = function(file, choice)
  child.sf_fake.install({
    { cmd = "sf org list", fixture = "org_list" },
    { cmd = "sf project retrieve start", code = 1 },
  })
  fetch_orgs()
  child.open_in_sf_dir(file)
  child.stub_select(choice)
  child.capture_notify()

  child.lua([[Sf.diff_in_org()]])
  child.sf_fake.wait()
  return child.sf_fake.cmds()[2]
end

T["diff_in_org()"]["passes a scratch org by name, without its [S] marker"] = function()
  local cmd = diff_in("force-app/main/default/classes/Hello.cls", "[S] my-scratch")

  helpers.expect.match(cmd, "^sf project retrieve start %-m 'ApexClass:Hello' ")
  helpers.expect.ends_with(cmd, " -o 'my-scratch'")
end

T["diff_in_org()"]["takes the type from the metadata folder, not a folder name containing another"] = function()
  -- "groupsList" contains "groups", the Group folder
  local cmd = diff_in("force-app/main/default/lwc/groupsList/groupsList.js", "uat")

  helpers.expect.match(cmd, "%-m 'LightningComponentBundle:groupsList' ")
end

T["diff_in_org()"]["shows a message when the file's metadata type is unknown"] = function()
  local cmd = diff_in("SfProject.cls", "uat")

  eq(cmd, nil)
  eq(child.select_calls(), {})
  eq(notified_errors(), { "Cannot diff SfProject.cls: its metadata type is unknown" })
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
