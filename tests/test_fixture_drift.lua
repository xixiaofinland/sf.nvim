-- The drift check runs in this Neovim, not a child: like the fixture recorder,
-- it is a dev script, not plugin code. A fake `gh` on PATH answers it; git is
-- real, with a bare repository as the remote.
local helpers = dofile("tests/helpers.lua")
local drift = dofile("scripts/fixture_drift.lua")
local eq = helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set()

T["shape_changes"] = new_set()

T["shape_changes"]["reports an added key"] = function()
  local changes = drift.shape_changes([[{"result": {"id": "a"}}]], [[{"result": {"id": "a", "name": "b"}}]])
  eq(changes, { added = { "result.name (string)" }, removed = {}, retyped = {} })
end

T["shape_changes"]["reports a removed key"] = function()
  local changes = drift.shape_changes([[{"result": {"id": "a", "name": "b"}}]], [[{"result": {"id": "a"}}]])
  eq(changes, { added = {}, removed = { "result.name (string)" }, retyped = {} })
end

T["shape_changes"]["reports a type change"] = function()
  local changes = drift.shape_changes([[{"result": {"size": 1}}]], [[{"result": {"size": "1"}}]])
  eq(changes, { added = {}, removed = {}, retyped = { "result.size: number → string" } })
end

T["shape_changes"]["does not report a changed value alone"] = function()
  local changes = drift.shape_changes(
    [[{"result": {"id": "a", "n": 1, "ok": true}}]],
    [[{"result": {"id": "b", "n": 2, "ok": false}}]]
  )
  eq(changes, { added = {}, removed = {}, retyped = {} })
end

T["shape_changes"]["merges the keys of every array item"] = function()
  local changes = drift.shape_changes(
    [[{"result": [{"id": "a"}, {"id": "b"}]}]],
    [[{"result": [{"id": "a"}, {"id": "b", "alias": "x"}]}]]
  )
  eq(changes, { added = { "result[].alias (string)" }, removed = {}, retyped = {} })
end

T["shape_changes"]["tells an empty object from an empty array, and null from a value"] = function()
  local changes =
    drift.shape_changes([[{"warnings": [], "result": {}, "x": null}]], [[{"warnings": {}, "result": {}, "x": "y"}]])
  eq(changes, { added = {}, removed = {}, retyped = { "warnings: array → object", "x: null → string" } })
end

T["shape_changes"]["names the top level ."] = function()
  eq(drift.shape_changes("[]", "{}"), { added = {}, removed = {}, retyped = { ".: array → object" } })
end

-- ── run

local recorder = dofile("scripts/fixture_recorder.lua")
local expect = helpers.expect

local FIXTURES = "tests/fixtures/sf"
local OLD_VERSION, NEW_VERSION = "@salesforce/cli/2.153.5", "@salesforce/cli/2.160.0"
local OLD_DISPLAY = [[{"status": 0, "result": {"id": "00D000000000001AAA", "alias": "my-scratch"}}]]
local NEW_DISPLAY = [[{"status": 0, "result": {"id": "00D000000000002AAA", "aliases": ["my-scratch"]}}]]
local HUMAN = "Test Run Id  707000000000001\nOutcome  Passed\n"

local SECRETS = {
  SF_DEVHUB_CLIENT_ID = "3MVG9fakeConsumerKeyOfTheDevHubApp",
  SF_DEVHUB_USERNAME = "jane.doe@acme-corp.com",
  SF_DEVHUB_JWT_KEY = "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASC\nBKcwggSjAgEAAoIBAQC7fakeKeyBody\n-----END PRIVATE KEY-----",
}
local HOME = "/home/runner"

local PR_URL = "https://github.com/xixiaofinland/sf.nvim/pull/7"
local ISSUE_URL = "https://github.com/xixiaofinland/sf.nvim/issues/9"
local NO_PR = { cmd = "pr list", stdout = "[]" }
local NO_ISSUE = { cmd = "issue list", stdout = "[]" }
local OPEN_ISSUE = {
  cmd = "issue list",
  stdout = vim.json.encode({
    { number = 3, body = "Something else entirely" },
    { number = 5, body = drift.MARKER .. "\nEarlier drift" },
  }),
}

local PASSING = { "sh", "-c", "echo 'Fails (0) and Notes (0)'" }
-- As mini.test prints it, colours included.
local FAILING = {
  "sh",
  "-c",
  [[printf '\033[1mFails (2) and Notes (0)\033[0m\n\n\033[1;31mFAIL\033[0m in tests/test_org.lua | fetch_org_list | sets the target org: Failed expectation for equality.\n\n\033[1;31mFAIL\033[0m in tests/test_org.lua | fetch_org_list | sets the target org: second line\n\033[1;31mFAIL\033[0m in tests/test_sobject.lua | refresh | describes: boom\n'; exit 1]],
}

local tmp, work, remote, original_path, original_git_config

---@param argv string[]
---@param cwd string|nil
---@return string stdout
local function git(argv, cwd)
  local result = vim
    .system(vim.list_extend({ "git", "-c", "user.name=t", "-c", "user.email=t@t" }, argv), {
      cwd = cwd or work,
      text = true,
    })
    :wait()
  if result.code ~= 0 then
    error("git " .. table.concat(argv, " ") .. ": " .. result.stderr, 0)
  end
  return result.stdout
end

local function render(name, stdout, version, date)
  return recorder.render({ shown = "sf " .. name, sf_version = version, date = date, code = 0, stdout = stdout })
end

local function write(path, text)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile(vim.split(text, "\n", { plain = true }), path, "b")
end

local function read(path)
  return table.concat(vim.fn.readfile(path, "b"), "\n")
end

-- What `make record-fixtures` leaves in the working tree.
local function record(fixtures)
  for name, text in pairs(fixtures) do
    write(work .. "/" .. FIXTURES .. "/" .. name .. ".lua", text)
  end
end

-- The same output as committed, recorded again with a newer CLI on a later day.
local function record_unchanged()
  record({
    org_display = render("org_display", OLD_DISPLAY, NEW_VERSION, "2026-10-23"),
    apex_run_test_human = render("apex_run_test_human", HUMAN, NEW_VERSION, "2026-10-23"),
  })
end

local function record_changed()
  record({
    org_display = render("org_display", NEW_DISPLAY, NEW_VERSION, "2026-10-23"),
    apex_run_test_human = render("apex_run_test_human", HUMAN, NEW_VERSION, "2026-10-23"),
  })
end

-- A fake `gh` on PATH. It logs each call to $tmp/gh/calls and copies each
-- `--body-file` to $tmp/gh/bodies/<call number>, then answers with the first
-- rule whose `cmd` its command line contains; with no rule, it prints nothing.
---@param rules { cmd: string, stdout: string|nil, code: integer|nil }[]
local function install_fake_gh(rules)
  local bin, dir = tmp .. "/bin", tmp .. "/gh"
  vim.fn.mkdir(bin, "p")
  vim.fn.mkdir(dir .. "/bodies", "p")
  for i, rule in ipairs(rules) do
    local rule_dir = string.format("%s/rules/%02d", dir, i)
    vim.fn.mkdir(rule_dir, "p")
    vim.fn.writefile({ rule.cmd }, rule_dir .. "/cmd")
    vim.fn.writefile(vim.split(rule.stdout or "", "\n"), rule_dir .. "/stdout", "b")
    vim.fn.writefile({ tostring(rule.code or 0) }, rule_dir .. "/code")
  end
  vim.fn.writefile({
    "#!/bin/sh",
    'D="' .. dir .. '"',
    'echo "$*" >> "$D/calls"',
    'n=$(wc -l < "$D/calls" | tr -d " ")',
    'prev=""',
    'for a in "$@"; do',
    '  [ "$prev" = "--body-file" ] && cp "$a" "$D/bodies/$n"',
    '  prev="$a"',
    "done",
    'for r in "$D"/rules/*; do',
    '  [ -d "$r" ] || continue',
    '  p=$(cat "$r/cmd")',
    '  case "$*" in *"$p"*) cat "$r/stdout"; exit "$(cat "$r/code")" ;; esac',
    "done",
  }, bin .. "/gh")
  vim.fn.setfperm(bin .. "/gh", "rwxr-xr-x")
  vim.env.PATH = bin .. ":" .. original_path
end

local function gh_calls()
  local path = tmp .. "/gh/calls"
  return vim.fn.filereadable(path) == 1 and vim.fn.readfile(path) or {}
end

-- The commands of the calls, without their flags' values.
local function gh_commands()
  return vim.tbl_map(function(call)
    return call:match("^(%S+ %S+)")
  end, gh_calls())
end

---@param pattern string Plain text the call contains
---@return integer|nil index
local function gh_call(pattern)
  for i, call in ipairs(gh_calls()) do
    if call:find(pattern, 1, true) then
      return i
    end
  end
end

local function gh_body(pattern)
  local i = gh_call(pattern)
  return i and read(tmp .. "/gh/bodies/" .. i)
end

local function remote_branches()
  return vim.split(vim.trim(git({ "branch", "--format=%(refname:short)" }, remote)), "\n")
end

local function run(test_cmd, secrets)
  return drift.run({
    root = work,
    fixtures = FIXTURES,
    base = "dev",
    secrets = secrets or SECRETS,
    home = HOME,
    test_cmd = test_cmd or PASSING,
    log = function() end,
  })
end

T["run"] = new_set({
  hooks = {
    pre_case = function()
      tmp = vim.fn.tempname()
      work, remote = tmp .. "/work", tmp .. "/remote.git"
      vim.fn.mkdir(work, "p")
      original_path = vim.env.PATH
      -- No hooks or signing from the user's own git config.
      original_git_config = vim.env.GIT_CONFIG_GLOBAL
      vim.env.GIT_CONFIG_GLOBAL = "/dev/null"
      git({ "init", "--bare", "-b", "dev", remote }, tmp)
      git({ "init", "-b", "dev" })
      git({ "remote", "add", "origin", remote })
      record({
        org_display = render("org_display", OLD_DISPLAY, OLD_VERSION, "2026-10-16"),
        apex_run_test_human = render("apex_run_test_human", HUMAN, OLD_VERSION, "2026-10-16"),
        -- Synthetic fixtures aren't re-recorded.
        synthetic = "return { recorded = false, code = 0, stdout = '{}' }",
      })
      git({ "add", "-A" })
      git({ "commit", "-m", "init" })
      git({ "push", "origin", "dev" })
    end,
    post_case = function()
      vim.env.PATH = original_path
      vim.env.GIT_CONFIG_GLOBAL = original_git_config
      vim.fn.delete(tmp, "rf")
    end,
  },
})

T["run"]["does nothing when only the RECORDED line changed"] = function()
  install_fake_gh({ NO_PR, NO_ISSUE })
  record_unchanged()

  eq(run().outcome, "unchanged")

  -- Only reads.
  eq(gh_commands(), { "pr list", "issue list" })
  eq(remote_branches(), { "dev" })
end

T["run"]["closes the drift PR and issue left open once dev matches the CLI again"] = function()
  install_fake_gh({ { cmd = "pr list", stdout = vim.json.encode({ { number = 7, url = PR_URL } }) }, OPEN_ISSUE })
  record_unchanged()

  eq(run().outcome, "unchanged")

  eq(gh_commands(), { "pr list", "issue list", "pr close", "issue close" })
  expect.match(gh_calls()[3], "^pr close 7 ")
  expect.match(gh_calls()[4], "^issue close 5 ")
end

T["run"]["opens and merges a PR when the output changed and the tests pass"] = function()
  install_fake_gh({ NO_PR, NO_ISSUE, { cmd = "pr create", stdout = PR_URL } })
  record_changed()

  local result = run(PASSING)

  eq(result.outcome, "merged")
  eq(result.pr, 7)
  eq(gh_commands(), { "pr list", "pr create", "issue list", "pr merge" })
  local title = "test: re-record fixtures for sf 2.160.0"
  expect.match(gh_calls()[2], vim.pesc("--base dev --head fixture-drift --title " .. title))
  expect.match(gh_calls()[4], "^pr merge 7 %-%-squash %-%-delete%-branch")
  -- The PR carries every re-recorded fixture, headers and all.
  eq(vim.trim(git({ "log", "-1", "--format=%s", "fixture-drift" }, remote)), title)
  eq(
    git({ "show", "fixture-drift:" .. FIXTURES .. "/org_display.lua" }, remote),
    read(work .. "/" .. FIXTURES .. "/org_display.lua")
  )
  local body = gh_body("pr create")
  expect.match(body, "org_display")
  expect.match(body, vim.pesc("Added: `result.aliases` (array)"))
  expect.no_match(body, "apex_run_test_human")
end

T["run"]["closes the open drift issue when the tests pass again"] = function()
  install_fake_gh({ NO_PR, OPEN_ISSUE, { cmd = "pr create", stdout = PR_URL } })
  record_changed()

  eq(run(PASSING).outcome, "merged")

  eq(gh_commands(), { "pr list", "pr create", "issue list", "pr merge", "issue close" })
  expect.match(gh_calls()[5], "^issue close 5 ")
end

T["run"]["opens a PR and a ready-for-agent issue when the tests fail"] = function()
  install_fake_gh({
    NO_PR,
    NO_ISSUE,
    { cmd = "pr create", stdout = PR_URL },
    { cmd = "issue create", stdout = ISSUE_URL },
  })
  record_changed()

  local result = run(FAILING)

  eq(result.outcome, "needs_fix")
  eq(result.pr, 7)
  eq(result.issue, 9)
  eq(gh_commands(), { "pr list", "pr create", "issue list", "issue create" })
  expect.match(gh_calls()[4], "%-%-label ready%-for%-agent")
  expect.match(gh_calls()[4], "%-%-title fix: ")
  local body = gh_body("issue create")
  expect.match(body, vim.pesc(drift.MARKER))
  expect.match(body, "#7")
  expect.match(body, "sf 2%.160%.0")
  expect.match(body, vim.pesc("`tests/test_org.lua | fetch_org_list | sets the target org`"))
  expect.match(body, vim.pesc("`tests/test_sobject.lua | refresh | describes`"))
  -- Once per test, however many expectations failed.
  eq(select(2, body:gsub("sets the target org", "")), 1)
  expect.match(body, vim.pesc("Added: `result.aliases` (array)"))
  expect.match(body, vim.pesc("Removed: `result.alias` (string)"))
  expect.no_match(body, "\27")
end

T["run"]["comments on the open drift issue instead of opening another"] = function()
  install_fake_gh({ { cmd = "pr list", stdout = vim.json.encode({ { number = 7, url = PR_URL } }) }, OPEN_ISSUE })
  record_changed()

  local result = run(FAILING)

  eq(result.outcome, "needs_fix")
  eq(result.issue, 5)
  -- The PR left open last time gets the new fixtures.
  eq(gh_commands(), { "pr list", "pr edit", "issue list", "issue comment" })
  expect.match(gh_calls()[2], "^pr edit 7 ")
  expect.match(gh_calls()[4], "^issue comment 5 ")
  local body = gh_body("issue comment")
  expect.match(body, vim.pesc("`tests/test_sobject.lua | refresh | describes`"))
  expect.match(body, vim.pesc("Removed: `result.alias` (string)"))
end

T["run"]["fails before any PR when a fixture holds a secret"] = new_set({
  parametrize = {
    { "SF_DEVHUB_CLIENT_ID", SECRETS.SF_DEVHUB_CLIENT_ID },
    { "SF_DEVHUB_USERNAME", SECRETS.SF_DEVHUB_USERNAME },
    -- One line of the key is as bad as all of it.
    { "SF_DEVHUB_JWT_KEY", "MIIEvQIBADANBgkqhkiG9w0BAQEFAASC" },
    { "the home directory", HOME .. "/.sf/key.pem" },
  },
}, {
  test = function(name, value)
    install_fake_gh({ NO_PR, NO_ISSUE, { cmd = "pr create", stdout = PR_URL } })
    record_changed()
    local leaked = NEW_DISPLAY:gsub("my%-scratch", value)
    record({ org_display = render("org_display", leaked, NEW_VERSION, "2026-10-23") })

    local ok, err = pcall(run, PASSING)

    eq(ok, false)
    expect.match(err, "org_display")
    expect.match(err, vim.pesc(name))
    expect.no_match(err, vim.pesc(value))
    eq(gh_calls(), {})
    eq(remote_branches(), { "dev" })
  end,
})

return T
