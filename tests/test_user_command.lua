local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.open_in_sf_dir("SfProject.cls")
      child.capture_notify()
    end,
    post_once = child.stop,
  },
})

---@param cmdline string What follows `:` on the command line
---@return string[]
local complete = function(cmdline)
  return child.fn.getcompletion(cmdline, "cmdline")
end

-- Replaces the function behind `:SF <group> <action>` with one recording its
-- arguments; read them with `stub_calls()`.
local stub_action = function(group, action)
  child.lua(
    [[
    local group, action = ...
    _G.stub_calls = {}
    require('sf.sub.config_user_command').sub_cmd_tbl[group].funcs[action] = function(...)
      table.insert(_G.stub_calls, { ... })
    end
  ]],
    { group, action }
  )
end

local stub_calls = function()
  return child.lua_get("_G.stub_calls")
end

T["completion"] = new_set()

T["completion"]["offers only groups starting with the typed prefix, sorted"] = function()
  eq(complete("SF t"), { "term", "test" })
  eq(complete("SF c"), { "create", "currentFile" })
end

T["completion"]["offers every group, sorted, for an empty argument"] = function()
  eq(complete("SF "), { "create", "currentFile", "md", "mdtype", "org", "sobject", "term", "test" })
end

T["completion"]["offers the actions of a group by prefix"] = function()
  eq(complete("SF term "), { "cancel", "toggle" })
  eq(complete("SF org set"), { "setGlobalTarget", "setTarget" })
end

T["completion"]["does not error on pattern characters"] = function()
  -- getcompletion() swallows a throwing completer, leaving only v:errmsg
  child.v.errmsg = ""
  eq(complete("SF %"), {})
  eq(complete("SF ("), {})
  eq(complete("SF org %("), {})
  eq(complete("SF sobject refresh %["), {})
  eq(child.v.errmsg, "")
end

T["completion"]["offers nothing past the action"] = function()
  eq(complete("SF term toggle "), {})
  eq(complete("SF unknown "), {})
end

T["completion"]["offers sobject refresh categories regardless of case"] = function()
  eq(complete("SF sobject refresh "), { "ALL", "CUSTOM", "STANDARD" })
  eq(complete("SF sobject refresh cu"), { "CUSTOM" })
  eq(complete("SF sobject refresh St"), { "STANDARD" })
end

T["execution"] = new_set()

T["execution"]["forwards every extra argument to push"] = function()
  child.lua([[require('sf.util').target_org = 'myorg']])
  child.sf_fake.install({ { cmd = "sf project deploy start" } })

  child.cmd("SF currentFile push --ignore-conflicts --dry-run")
  child.sf_fake.wait()

  local cmds = child.sf_fake.cmds()
  eq(#cmds, 1)
  expect.match(cmds[1], "%-%-ignore%-conflicts %-%-dry%-run")
end

T["execution"]["calls an action without extra arguments with none"] = function()
  stub_action("term", "toggle")

  child.cmd("SF term toggle")

  eq(stub_calls(), { {} })
end

T["execution"]["refuses extra arguments to an action that takes none"] = function()
  stub_action("term", "toggle")

  child.cmd("SF term toggle extra")

  eq(stub_calls(), {})
  expect.match(child.notified()[1].msg, "'term toggle' takes no arguments")
end

T["execution"]["accepts a sobject refresh category in any case"] = function()
  stub_action("sobject", "refresh")

  child.cmd("SF sobject refresh custom")

  eq(stub_calls(), { { { category = "CUSTOM" } } })
end

T["execution"]["refuses an unknown sobject refresh category"] = function()
  stub_action("sobject", "refresh")

  child.cmd("SF sobject refresh bogus")

  eq(stub_calls(), {})
  expect.match(child.notified()[1].msg, "Invalid category")
end

T["execution"]["names the valid groups for an unknown group"] = function()
  child.cmd("SF bogus toggle")

  local msg = child.notified()[1].msg
  expect.match(msg, "Unknown group 'bogus'")
  expect.match(msg, "currentFile")
end

T["execution"]["names the valid actions for an unknown action"] = function()
  child.cmd("SF term bogus")

  local msg = child.notified()[1].msg
  expect.match(msg, "Unknown action 'bogus' for 'term'")
  expect.match(msg, "cancel, toggle")
end

T["execution"]["names the valid actions when the action is missing"] = function()
  child.cmd("SF term")

  local msg = child.notified()[1].msg
  expect.match(msg, "Missing action for 'term'")
  expect.match(msg, "cancel, toggle")
end

return T
