-- The fixture recorder runs in this Neovim, not a child: it is a dev script,
-- not plugin code. A fake `sf` shell script on PATH answers it.
local helpers = dofile("tests/helpers.lua")
local recorder = dofile("scripts/fixture_recorder.lua")
local eq = helpers.expect.equality
local expect = helpers.expect
local new_set = MiniTest.new_set

local SCRATCH = recorder.SCRATCH_ALIAS
local DEVHUB = "my-devhub"

-- Shaped like `sf org display --json` on a scratch org (sf CLI 2.x), with
-- made-up but realistic values: none of them may survive scrubbing.
local REAL_ORG_ID = "00DKj00000AbCdEMAZ"
local REAL_DEVHUB_ID = "00D5g00000XyZwVUAR"
local REAL_TOKEN = "00DKj00000AbCdE!AQ8AQGv3yP2kR9x.Zq1mN0bHt7Yd_wLsVxEo4uJfIrCg6KpTnMa"
local REAL_USERNAME = "test-k2jxq9vbpw1m@example.com"
local REAL_DEVHUB_USERNAME = "jane.doe@acme-corp.com"
local REAL_INSTANCE = "https://acme-corp-dev-ed.scratch.my.salesforce.com"
local REAL_LOGIN = "https://CS42.salesforce.com"
local REAL_CREATED = "2026-10-14T09:31:27.000+0000"
local REAL_EXPIRES = "2026-10-21"
local REAL_REFRESH_TOKEN = "NOT_A_REAL_REFRESH_TOKEN_r7Wd3QzLx0vB"
local REAL_AUTH_URL = "force://PlatformCLI::" .. REAL_REFRESH_TOKEN .. "@acme-corp-dev-ed.scratch.my.salesforce.com"
local REAL_TEST_RUN_ID = "707Kj00000XyZ12"

local REAL_OUTPUT = string.format(
  [[
{
  "status": 0,
  "result": {
    "id": "%s",
    "apiVersion": "65.0",
    "accessToken": "%s",
    "instanceUrl": "%s",
    "loginUrl": "%s",
    "username": "%s",
    "clientId": "PlatformCLI",
    "connectedStatus": "Connected",
    "alias": "%s",
    "password": "x7&k#Qp2mZ",
    "createdBy": "%s",
    "createdDate": "%s",
    "devHubId": "%s",
    "edition": "Developer",
    "expirationDate": "%s",
    "orgName": "Acme Corp",
    "sfdxAuthUrl": "%s",
    "status": "Active"
  },
  "warnings": [
    "This command will expose sensitive information that allows for subsequent activity using your current authenticated session for %s at %s."
  ]
}
]],
  REAL_ORG_ID,
  REAL_TOKEN,
  REAL_INSTANCE,
  REAL_LOGIN,
  REAL_USERNAME,
  SCRATCH,
  REAL_DEVHUB_USERNAME,
  REAL_CREATED,
  REAL_DEVHUB_ID,
  REAL_EXPIRES,
  REAL_AUTH_URL,
  REAL_USERNAME,
  REAL_INSTANCE
)

-- The other commands answer with the shipped fixtures, their placeholders
-- swapped for realistic values like those above.
local REAL_VALUES = {
  { "00D000000000001AAA", REAL_DEVHUB_ID },
  { "00D000000000004AAA", REAL_ORG_ID },
  { "test-fake1234@example.com", REAL_USERNAME },
  { "admin@example.com", REAL_DEVHUB_USERNAME },
  { "fake-scratch-1234", "acme-corp-dev-ed" },
  { "fake-company", "acme-corp" },
  { "fake-other", "globex" },
  { "Fake Company", "Acme Corp" },
  { "Fake Admin", "Jane Doe" },
  { "FAKE_ACCESS_TOKEN", "AQ8AQGv3yP2kR9x" },
  { "707000000000001", REAL_TEST_RUN_ID },
  { "707000000000002", "707Kj00000XyZ34" },
  { "005000000000001AAA", "005Kj00000LmNoPQRS" },
  { "005000000000002AAA", "005Kj00000TuVwXQAY" },
  { "01p000000000001AAA", "01pKj00000AaBbCQAU" },
  { "01p000000000002AAA", "01pKj00000DdEeFQAU" },
  { "01p000000000003AAA", "01pKj00000GgHhIQAU" },
  { "07M000000000001AAA", "07MKj00000JjKkLQAU" },
  { "07M000000000002AAA", "07MKj00000MmNnOQAU" },
  { "709000000000001AAA", "709Kj00000PpQqRQAU" },
  { "2026-01-01T09:00:00.000Z", "2026-10-14T09:31:27.000Z" },
  { "1/1/2026, 9:00:00 AM", "10/14/2026, 9:31:27 PM" },
  { "52 ms", "57 ms" },
  { "95 ms", "103 ms" },
  { "120 ms", "131 ms" },
  { '"RunTime": 30', '"RunTime": 34' },
  { "Pass              30", "Pass              34" },
  { '"alias": "devhub"', '"alias": "' .. DEVHUB .. '"' },
  { '"alias": "my-scratch"', '"alias": "' .. SCRATCH .. '"' },
  {
    '"headers": { "content-type"',
    '"headers": { "date": "Wed, 14 Oct 2026 09:31:27 GMT", "sforce-limit-info": "api-usage=12/15000", "content-type"',
  },
}

local SECRETS = {
  REAL_ORG_ID,
  REAL_ORG_ID:sub(1, 15),
  REAL_DEVHUB_ID,
  REAL_TOKEN,
  REAL_USERNAME,
  REAL_DEVHUB_USERNAME,
  REAL_INSTANCE,
  REAL_INSTANCE:match("//(.*)"),
  REAL_LOGIN,
  "x7&k#Qp2mZ",
  SCRATCH,
  DEVHUB,
  "Acme Corp",
  "acme-corp",
  "globex",
  "Jane Doe",
  REAL_CREATED,
  REAL_EXPIRES,
  "2026-10-14",
  "10/14/2026",
  REAL_REFRESH_TOKEN,
  REAL_TEST_RUN_ID,
  "AQ8AQGv3yP2kR9x",
  "api-usage",
  "57 ms",
  "103 ms",
  "131 ms",
}
for _, pair in ipairs(REAL_VALUES) do
  if pair[2]:match("^%w+$") and #pair[2] == 18 then
    table.insert(SECRETS, pair[2])
  end
end

local function expect_scrubbed(text)
  for _, secret in ipairs(SECRETS) do
    if text:find(secret, 1, true) then
      error("scrubbed output still contains " .. secret, 0)
    end
  end
end

---@param name string A shipped fixture
---@return string
local function real(name)
  local text = helpers.sf_fixture(name).stdout
  for _, pair in ipairs(REAL_VALUES) do
    text = text:gsub(vim.pesc(pair[1]), (pair[2]:gsub("%%", "%%%%")))
  end
  return text
end

local tmp, original_path

-- A fake `sf` on PATH. It logs each call to $tmp/sf/calls, copies a request
-- body (`--body @file`) to $tmp/sf/body, lists the files of the project a
-- deploy runs in to $tmp/sf/deployed and writes the signup app a scratch org
-- create sees to $tmp/sf/signup_app. It answers `--version` itself and any
-- other call with the first rule whose `cmd` its command line contains.
---@param rules { cmd: string, stdout: string|nil, stderr: string|nil, code: integer|nil }[]
local function install_fake_sf(rules)
  local bin, dir = tmp .. "/bin", tmp .. "/sf"
  vim.fn.mkdir(bin, "p")
  vim.fn.delete(dir .. "/rules", "rf")
  for i, rule in ipairs(rules) do
    local rule_dir = string.format("%s/rules/%02d", dir, i)
    vim.fn.mkdir(rule_dir, "p")
    vim.fn.writefile({ rule.cmd }, rule_dir .. "/cmd")
    vim.fn.writefile(vim.split(rule.stdout or "", "\n"), rule_dir .. "/stdout", "b")
    vim.fn.writefile(vim.split(rule.stderr or "", "\n"), rule_dir .. "/stderr", "b")
    vim.fn.writefile({ tostring(rule.code or 0) }, rule_dir .. "/code")
  end
  vim.fn.writefile({
    "#!/bin/sh",
    'D="' .. dir .. '"',
    'echo "$*" >> "$D/calls"',
    'for a in "$@"; do case "$a" in @*) cp "${a#@}" "$D/body" ;; esac; done',
    'case "$*" in "project deploy start"*) find . -type f | LC_ALL=C sort >"$D/deployed" ;; esac',
    'case "$*" in "org create scratch"*)',
    '  printf "%s\\n%s\\n" "$SF_SCRATCH_SIGNUP_CONNECTED_APP" "$SF_SCRATCH_SIGNUP_CALLBACK_URL" >"$D/signup_app" ;;',
    "esac",
    'if [ "$1" = "--version" ]; then',
    '  echo "@salesforce/cli/2.108.6 linux-x64 node-v22.20.0"',
    "  exit 0",
    "fi",
    'for r in "$D"/rules/*; do',
    '  p=$(cat "$r/cmd")',
    '  case "$*" in *"$p"*)',
    '    cat "$r/stdout"; cat "$r/stderr" >&2; exit "$(cat "$r/code")" ;;',
    "  esac",
    "done",
    'echo "fake sf: no rule for: $*" >&2',
    "exit 127",
  }, bin .. "/sf")
  vim.fn.setfperm(bin .. "/sf", "rwxr-xr-x")
  vim.env.PATH = bin .. ":" .. original_path
end

local function sf_calls()
  return vim.fn.filereadable(tmp .. "/sf/calls") == 1 and vim.fn.readfile(tmp .. "/sf/calls") or {}
end

local function read(path)
  return table.concat(vim.fn.readfile(path, "b"), "\n")
end

local CREATE_OUTPUT = string.format(
  [[{"status": 0, "result": {"username": "%s", "orgId": "%s", "scratchOrgInfo": {}, "warnings": []}, "warnings": []}]],
  REAL_USERNAME,
  REAL_ORG_ID
)
local DEPLOY_OUTPUT = [[{"status": 0, "result": {"status": "Succeeded", "success": true}, "warnings": []}]]
local DELETE_OUTPUT = string.format([[{"status": 0, "result": {"orgId": "%s"}, "warnings": []}]], REAL_ORG_ID)
local GET_TEST_ERROR_CMD = "apex get test -i 707000000000000"

-- The answers of a run in which every step succeeds. More specific commands
-- come first: the first rule that matches answers.
local function rules_for_success()
  return {
    { cmd = "org create scratch", stdout = CREATE_OUTPUT },
    { cmd = "project deploy start", stdout = DEPLOY_OUTPUT },
    { cmd = "org display", stdout = REAL_OUTPUT },
    { cmd = "org list metadata", stdout = real("org_list_metadata") },
    { cmd = "org list --json", stdout = real("org_list") },
    { cmd = "sobject list", stdout = real("sobject_list") },
    { cmd = "--header", code = 1, stdout = real("api_request_rest_401") },
    { cmd = "composite/batch", stdout = real("api_request_rest_composite_batch") },
    { cmd = "-r human", stdout = real("apex_run_test_human") },
    { cmd = "apex run test", stdout = real("apex_run_test") },
    { cmd = GET_TEST_ERROR_CMD, code = 1, stdout = real("apex_get_test_error") },
    { cmd = "apex get test -i " .. REAL_TEST_RUN_ID, stdout = real("apex_get_test_coverage") },
    { cmd = "org delete scratch", stdout = DELETE_OUTPUT },
  }
end

local function fixture_names()
  return vim.tbl_map(function(spec)
    return spec.name
  end, recorder.FIXTURES)
end

local OLD_FIXTURE = "-- old fixture\nreturn { recorded = false, code = 0, stdout = '{}' }\n"

local function write_old_fixtures()
  for _, name in ipairs(fixture_names()) do
    vim.fn.writefile(vim.split(OLD_FIXTURE, "\n"), tmp .. "/" .. name .. ".lua", "b")
  end
end

local function expect_old_fixtures()
  for _, name in ipairs(fixture_names()) do
    eq(read(tmp .. "/" .. name .. ".lua"), OLD_FIXTURE)
  end
  eq(
    vim.fn.readdir(tmp, function(name)
      return name:match("%.tmp$") and 1 or 0
    end),
    {}
  )
end

local function count_calls(pattern)
  return #vim.tbl_filter(function(call)
    return call:find(pattern, 1, true) ~= nil
  end, sf_calls())
end

local DELETE_CALL = "org delete scratch -o " .. SCRATCH .. " --no-prompt --json"

local function record()
  return recorder.record({ devhub = DEVHUB, dir = tmp, date = "2026-10-15" })
end

local T = new_set({
  hooks = {
    pre_case = function()
      tmp = vim.fn.tempname()
      vim.fn.mkdir(tmp, "p")
      original_path = vim.env.PATH
    end,
    post_case = function()
      vim.env.PATH = original_path
      vim.fn.delete(tmp, "rf")
    end,
  },
})

T["scrub"] = new_set()

T["scrub"]["leaves no token, id, username, URL or timestamp of the org"] = function()
  local scrubbed = recorder.scrub(REAL_OUTPUT)

  expect_scrubbed(scrubbed)
  local result = vim.json.decode(scrubbed).result
  eq(result.id, "00D000000000001AAA")
  eq(result.devHubId, "00D000000000002AAA")
  eq(result.accessToken, "00D000000000001!FAKE_ACCESS_TOKEN_1")
  eq(result.username, "admin@example.com")
  eq(result.createdBy, "user2@example.com")
  eq(result.instanceUrl, "https://fake-company.my.salesforce.com")
  eq(result.loginUrl, "https://fake-company-2.my.salesforce.com")
  eq(result.createdDate, "2026-01-01T00:00:00.000+0000")
  eq(result.expirationDate, "2026-01-01")
  eq(result.apiVersion, "62.0")
  eq(result.sfdxAuthUrl, "force://PlatformCLI::FAKE_REFRESH_TOKEN_1@fake-company.my.salesforce.com")
end

T["scrub"]["keeps the CLI's layout and values that aren't org-specific"] = function()
  local scrubbed = recorder.scrub(REAL_OUTPUT)

  local before, after = vim.split(REAL_OUTPUT, "\n"), vim.split(scrubbed, "\n")
  eq(#after, #before)
  for i = 1, #before do
    eq(after[i]:match('^%s*"(%w+)":'), before[i]:match('^%s*"(%w+)":'))
  end
  local result = vim.json.decode(scrubbed).result
  eq(result.clientId, "PlatformCLI")
  eq(result.connectedStatus, "Connected")
  eq(result.edition, "Developer")
  eq(result.status, "Active")
end

T["scrub"]["gives the same output for the same input"] = function()
  eq(recorder.scrub(REAL_OUTPUT), recorder.scrub(REAL_OUTPUT))
end

T["scrub"]["scrubs stderr with the same placeholders"] = function()
  local _, stderr = recorder.scrub(REAL_OUTPUT, "Warning: token " .. REAL_TOKEN .. " for " .. REAL_USERNAME)
  eq(stderr, "Warning: token 00D000000000001!FAKE_ACCESS_TOKEN_1 for admin@example.com")
end

T["scrub"]["scrubs a JWT-authorised org's key path, client id and org name"] = function()
  local home = vim.uv.os_homedir()
  local scrubbed = recorder.scrub(string.format(
    [[
{
  "status": 0,
  "result": {
    "devHubs": [
      {
        "orgId": "%s",
        "username": "%s",
        "privateKey": "%s/.config/acme/server.key",
        "clientId": "3MVG9AbCdEfGhIjKlMnOpQrStUvWxYz0123456789AbCdEfGhIjKlMnOpQrStUvWxYz==",
        "name": "acme-dev"
      }
    ],
    "scratchOrgs": [{ "orgId": "%s", "clientId": "PlatformCLI" }]
  },
  "warnings": []
}
]],
    REAL_DEVHUB_ID,
    REAL_DEVHUB_USERNAME,
    home,
    REAL_ORG_ID
  ))

  expect.no_equality(scrubbed:find(home, 1, true) ~= nil, true)
  expect.no_equality(scrubbed:find("3MVG9AbCd", 1, true) ~= nil, true)
  expect.no_equality(scrubbed:find("acme-dev", 1, true) ~= nil, true)
  local result = vim.json.decode(scrubbed).result
  eq(result.devHubs[1].privateKey, "/home/user/.config/acme/server.key")
  eq(result.devHubs[1].clientId, "FAKE_CLIENT_ID_1")
  eq(result.devHubs[1].name, "Fake Company")
  eq(result.scratchOrgs[1].clientId, "PlatformCLI")
end

T["scrub"]["replaces the home directory in a stack trace"] = function()
  local home = vim.uv.os_homedir()
  local scrubbed = recorder.scrub(vim.json.encode({
    name = "Error",
    stack = "Error: no results\n    at Test.catch (file://" .. home .. "/.npm-global/lib/sfCommand.js:333:47)",
  }))

  eq(
    vim.json.decode(scrubbed).stack,
    "Error: no results\n    at Test.catch (file:///home/user/.npm-global/lib/sfCommand.js:333:47)"
  )
end

T["scrub"]["replaces a short alias only as a whole word"] = function()
  local scrubbed = recorder.scrub(
    [[{"status": 0, "result": {"alias": "on", "connectedStatus": "Connected"}, "warnings": ["Logged in to on."]}]]
  )
  local decoded = vim.json.decode(scrubbed)
  eq(decoded.result, { alias = "devhub", connectedStatus = "Connected" })
  eq(decoded.warnings, { "Logged in to devhub." })
end

T["scrub"]["replaces the alias the command was given where sf only mentions it"] = function()
  local scrubbed =
    recorder.scrub([[{"status": 0, "result": {}, "warnings": ["Org my-org expires soon."]}]], nil, "my-org")
  eq(vim.json.decode(scrubbed).warnings, { "Org devhub expires soon." })
end

T["scrub"]["normalises durations, response headers and local timestamps, keeping the layout"] = function()
  local json = [[
{
  "status": 0,
  "result": {
    "summary": { "commandTime": "95 ms", "testExecutionTimeInMs": 52 },
    "tests": [{ "RunTime": 30, "Outcome": "Pass" }, { "RunTime": 7, "Outcome": "Pass" }],
    "headers": { "date": "Wed, 14 Oct 2026 09:31:27 GMT", "set-cookie": ["BrowserId=abc"], "content-type": "application/json" },
    "lastRetrieved": "10/14/2026, 9:31:27 PM",
    "lastUsedLocal": "10/14/2026, 10:31:27 PM",
    "statusCode": 200
  }
}]]

  local scrubbed = recorder.scrub(json)

  eq(
    scrubbed,
    [[
{
  "status": 0,
  "result": {
    "summary": { "commandTime": "0 ms", "testExecutionTimeInMs": 0 },
    "tests": [{ "RunTime": 0, "Outcome": "Pass" }, { "RunTime": 0, "Outcome": "Pass" }],
    "headers": { "date": "FAKE_HEADER_VALUE", "set-cookie": ["FAKE_HEADER_VALUE"], "content-type": "application/json" },
    "lastRetrieved": "1/1/2026, 0:00:00 AM",
    "lastUsedLocal": "1/1/2026, 0:00:00 AM",
    "statusCode": 200
  }
}]]
  )
end

T["scrub"]["shares placeholders across calls, for both forms of an id"] = function()
  local scrubber = recorder.new_scrubber()
  local first = scrubber:json([[{"status": 0, "result": {"AsyncApexJobId": "707Kj00000XyZ12"}}]])
  local second = scrubber:json([[{"status": 0, "result": {"Id": "707Kj00000XyZ12QAU", "ParentId": "707Kj00000OtHeR"}}]])

  eq(vim.json.decode(first).result.AsyncApexJobId, "707000000000001")
  eq(vim.json.decode(second).result, { Id = "707000000000001AAA", ParentId = "707000000000002" })
end

T["scrub"]["scrubs human-readable output with what JSON output showed"] = function()
  local scrubber = recorder.new_scrubber()
  scrubber:json(REAL_OUTPUT)

  local text = scrubber:text(real("apex_run_test_human"):gsub(vim.pesc(REAL_DEVHUB_ID), REAL_ORG_ID))

  expect_scrubbed(text)
  -- sf pads the columns with trailing spaces.
  expect.match(text, "\nTest Run Id          707000000000001 *\n")
  expect.match(text, "\nTest Execution Time  0 ms *\n")
  expect.match(text, "\nOrg Id               00D000000000001AAA *\n")
  expect.match(text, "\nSfProjectTest.constructsWithName  Pass              0 *\n")
  expect.match(text, "\nSfProjectTest.constructsWithNull  Pass              0 *\n")
  expect.match(text, "\nTests Ran            2 *\n")
end

T["record"] = new_set()

T["record"]["records every fixture the sf fake ships, scrubbed"] = function()
  install_fake_sf(rules_for_success())

  local paths = record()

  local shipped = vim.fn.readdir(recorder.fixtures_dir, function(name)
    return name:match("%.lua$") and 1 or 0
  end)
  eq(
    vim.tbl_map(function(path)
      return vim.fn.fnamemodify(path, ":t")
    end, paths),
    vim.tbl_map(function(name)
      return name .. ".lua"
    end, fixture_names())
  )
  table.sort(paths)
  eq(
    vim.tbl_map(function(path)
      return vim.fn.fnamemodify(path, ":t")
    end, paths),
    shipped
  )
  for _, path in ipairs(paths) do
    local content = read(path)
    expect_scrubbed(content)
    expect.match(content, "RECORDED with @salesforce/cli/2%.108%.6 on 2026%-10%-15")
    eq(dofile(path).recorded, true)
  end
  eq(dofile(tmp .. "/api_request_rest_401.lua").code, 1)
  eq(dofile(tmp .. "/apex_get_test_error.lua").code, 1)
end

T["record"]["creates one scratch org, deploys the project, records against it and deletes it"] = function()
  install_fake_sf(rules_for_success())

  record()

  local calls = sf_calls()
  eq(calls[1], "--version")
  eq(
    calls[2],
    "org create scratch --target-dev-hub my-devhub --alias "
      .. SCRATCH
      .. " --set-default --definition-file config/project-scratch-def.json --duration-days 1 --wait 15 --json"
  )
  eq(calls[3], "project deploy start --source-dir force-app -o " .. SCRATCH .. " --wait 15 --json")
  eq(calls[#calls], DELETE_CALL)
  eq(#calls, 4 + #recorder.FIXTURES)
  eq(count_calls("org create scratch"), 1)
  -- `org list` lists every org; each other command targets the scratch org.
  for i = 4, #calls - 1 do
    if not calls[i]:match("^org list %-%-json") then
      expect.match(calls[i], "%-o " .. vim.pesc(SCRATCH) .. "%f[%s%z]")
    end
  end
  eq(vim.fn.readfile(tmp .. "/sf/deployed"), {
    "./config/project-scratch-def.json",
    "./force-app/main/default/classes/SfProject.cls",
    "./force-app/main/default/classes/SfProject.cls-meta.xml",
    "./force-app/main/default/classes/SfProjectTest.cls",
    "./force-app/main/default/classes/SfProjectTest.cls-meta.xml",
    "./sfdx-project.json",
  })
end

T["record"]["signs the scratch org up through the CLI's own connected app"] = function()
  install_fake_sf(rules_for_success())

  record()

  eq(vim.fn.readfile(tmp .. "/sf/signup_app"), { "PlatformCLI", "http://localhost:1717/OauthRedirect" })
end

T["record"]["describes through the org's API version and fetches the coverage of the human run"] = function()
  install_fake_sf(rules_for_success())

  record()

  local calls = sf_calls()
  expect.match(table.concat(calls, "\n"), "\napi request rest services/data/v65%.0/composite/batch %-%-method POST")
  eq(
    vim.json.decode(read(tmp .. "/sf/body")).batchRequests[1],
    { method = "GET", url = "v65.0/sobjects/Account/describe" }
  )
  eq(count_calls("apex get test -i " .. REAL_TEST_RUN_ID .. " -c --json"), 1)

  local batch = read(tmp .. "/api_request_rest_composite_batch.lua")
  expect.match(
    batch,
    "^%-%- `sf api request rest services/data/v62%.0/composite/batch %-%-method POST %-%-body @<file> %-o my%-scratch %-%-json`"
  )
  local headers = vim.json.decode(dofile(tmp .. "/api_request_rest_composite_batch.lua").stdout).result.headers
  eq(headers["content-type"], "application/json;charset=UTF-8")
  eq(headers.date, "FAKE_HEADER_VALUE")
  eq(headers["sforce-limit-info"], "FAKE_HEADER_VALUE")
  for name, value in pairs(headers) do
    if name ~= "content-type" then
      for _, v in ipairs(type(value) == "table" and value or { value }) do
        eq(v, "FAKE_HEADER_VALUE")
      end
    end
  end

  -- The run id the human output shows is the one the coverage belongs to.
  local human = dofile(tmp .. "/apex_run_test_human.lua").stdout
  local run_id = human:match("Test Run Id%s+(%w+)")
  local coverage = vim.json.decode(dofile(tmp .. "/apex_get_test_coverage.lua").stdout).result
  eq(coverage.summary.testRunId, run_id)
  expect.match(
    read(tmp .. "/apex_get_test_coverage.lua"),
    "^%-%- `sf apex get test %-i " .. run_id .. " %-c %-%-json %-o my%-scratch`"
  )
end

T["record"]["names the Dev Hub devhub and the scratch org my-scratch"] = function()
  install_fake_sf(rules_for_success())

  record()

  local result = vim.json.decode(dofile(tmp .. "/org_list.lua").stdout).result
  eq(result.devHubs[1].alias, "devhub")
  eq(result.scratchOrgs[1].alias, "my-scratch")
  eq(result.scratchOrgs[1].lastUsed, "2026-01-01T00:00:00.000Z")
  eq(result.scratchOrgs[1].instanceApiVersionLastRetrieved, "1/1/2026, 0:00:00 AM")
  expect.match(read(tmp .. "/org_display.lua"), "^%-%- `sf org display %-o my%-scratch %-%-json`\n")
end

T["record"]["normalises what changes on every run"] = function()
  install_fake_sf(rules_for_success())

  record()

  local run = vim.json.decode(dofile(tmp .. "/apex_run_test.lua").stdout).result
  eq(run.summary.commandTime, "0 ms")
  eq(run.summary.testExecutionTime, "0 ms")
  eq(run.summary.testStartTime, "2026-01-01T00:00:00.000Z")
  eq(run.tests[1].RunTime, 0)
  -- Placeholders are numbered in the order the recording meets them.
  expect.match(run.tests[1].Id, "^07M0000000000%d%dAAA$")
  expect.match(run.summary.testRunId, "^7070000000000%d%d$")
end

T["record"]["writes identical files for the same org"] = function()
  install_fake_sf(rules_for_success())

  local first = vim.tbl_map(read, record())
  local second = vim.tbl_map(read, record())

  eq(second, first)
end

-- Each step, by a command line only it runs, and whether it is meant to fail.
local STEPS = {
  { cmd = "org create scratch" },
  { cmd = "project deploy start" },
  { cmd = "org display" },
  { cmd = "org list --json" },
  { cmd = "sobject list" },
  { cmd = "composite/batch" },
  { cmd = "--header", fails = true },
  { cmd = "-r human" },
  { cmd = "apex get test -i " .. REAL_TEST_RUN_ID },
  { cmd = "-w 5 -c --json" },
  { cmd = GET_TEST_ERROR_CMD, fails = true },
  { cmd = "org list metadata" },
}

for _, step in ipairs(STEPS) do
  T["record"]["deletes the scratch org and leaves the fixtures untouched when this fails: " .. step.cmd] = function()
    local rules = rules_for_success()
    -- A step meant to fail goes wrong by succeeding.
    table.insert(rules, 1, {
      cmd = step.cmd,
      code = step.fails and 0 or 1,
      stdout = step.fails and '{"status": 0, "result": {}}' or '{"status": 1, "message": "Step failed."}',
    })
    install_fake_sf(rules)
    write_old_fixtures()

    local ok, err = pcall(record)

    eq(ok, false)
    expect.match(err, vim.pesc(step.cmd))
    expect.match(err, step.fails and "was expected to fail" or "exited with 1: Step failed%.")
    expect.match(err, "\nThe existing fixtures were left untouched%.$")
    expect_old_fixtures()
    eq(count_calls("org create scratch"), 1)
    eq(count_calls("org delete scratch"), 1)
    local calls = sf_calls()
    eq(calls[#calls], DELETE_CALL)
  end
end

T["record"]["records no 401 fixture from a request that failed otherwise"] = function()
  local rules = rules_for_success()
  table.insert(rules, 1, { cmd = "--header", code = 1, stdout = '{"status": 1, "message": "getaddrinfo ENOTFOUND"}' })
  install_fake_sf(rules)
  write_old_fixtures()

  local ok, err = pcall(record)

  eq(ok, false)
  expect.match(err, "^the describe batch with a bad session got no HTTP response, not 401: getaddrinfo ENOTFOUND\n")
  expect_old_fixtures()
  eq(count_calls("org delete scratch"), 1)
end

T["record"]["says so when deleting the org fails after a failed step"] = function()
  local rules = rules_for_success()
  table.insert(rules, 1, { cmd = "org delete scratch", code = 1, stdout = '{"status": 1, "message": "No such org."}' })
  table.insert(rules, 1, { cmd = "sobject list", code = 1, stdout = '{"status": 1, "message": "Step failed."}' })
  install_fake_sf(rules)
  write_old_fixtures()

  local ok, err = pcall(record)

  eq(ok, false)
  expect.match(err, "exited with 1: Step failed%.\nThe existing fixtures were left untouched%.\n")
  expect.match(
    err,
    "Deleting the scratch org failed too: .*No such org%.\nDelete it by hand with `sf org delete scratch %-o "
  )
  expect_old_fixtures()
end

T["record"]["writes the fixtures and says so when only deleting the org fails"] = function()
  local rules = rules_for_success()
  table.insert(rules, 1, { cmd = "org delete scratch", code = 1, stdout = '{"status": 1, "message": "No such org."}' })
  install_fake_sf(rules)

  local ok, err = pcall(record)

  eq(ok, false)
  expect.match(err, "^The fixtures were recorded, but deleting the scratch org failed: .*No such org%.")
  expect.match(err, "`sf org delete scratch %-o " .. vim.pesc(SCRATCH) .. " %-%-no%-prompt`")
  eq(dofile(tmp .. "/org_display.lua").recorded, true)
end

T["record"]["creates no org when sf is missing"] = function()
  vim.env.PATH = tmp .. "/no-bin"
  write_old_fixtures()

  local ok, err = pcall(record)

  eq(ok, false)
  expect.match(err, "^could not run `sf %-%-version`")
  expect_old_fixtures()
end

T["command"] = new_set()

local function run_script(devhub)
  local argv = { vim.v.progpath, "-l", "scripts/record_fixtures.lua" }
  if devhub then
    vim.list_extend(argv, { devhub, tmp })
  end
  return vim.system(argv, { text = true }):wait()
end

T["command"]["records the fixtures given a Dev Hub alias"] = function()
  install_fake_sf(rules_for_success())

  local result = run_script(DEVHUB)

  eq(result.code, 0)
  local expected = vim.tbl_map(function(name)
    return "Recorded " .. tmp .. "/" .. name .. ".lua"
  end, fixture_names())
  eq(result.stdout, table.concat(expected, "\n") .. "\n")
  eq(dofile(tmp .. "/org_display.lua").recorded, true)
end

T["command"]["exits non-zero with a clear message when a step fails"] = function()
  local rules = rules_for_success()
  table.insert(rules, 1, { cmd = "org create scratch", code = 1, stdout = "", stderr = "sf: command exploded" })
  install_fake_sf(rules)
  write_old_fixtures()

  local result = run_script(DEVHUB)

  eq(result.code, 1)
  expect.match(result.stderr, "^record_fixtures: `sf org create scratch .* exited with 1: sf: command exploded\n")
  expect.match(result.stderr, "The existing fixtures were left untouched%.\n$")
  expect_old_fixtures()
end

T["command"]["asks for a Dev Hub alias"] = function()
  local result = run_script(nil)

  eq(result.code, 2)
  expect.match(result.stderr, "^usage: ")
end

return T
