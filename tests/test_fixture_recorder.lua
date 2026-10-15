-- The fixture recorder runs in this Neovim, not a child: it is a dev script,
-- not plugin code. A fake `sf` shell script on PATH answers it.
local helpers = dofile("tests/helpers.lua")
local recorder = dofile("scripts/fixture_recorder.lua")
local eq = helpers.expect.equality
local expect = helpers.expect
local new_set = MiniTest.new_set

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
    "alias": "my-scratch",
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
  REAL_DEVHUB_USERNAME,
  REAL_CREATED,
  REAL_DEVHUB_ID,
  REAL_EXPIRES,
  REAL_AUTH_URL,
  REAL_USERNAME,
  REAL_INSTANCE
)

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
  "my-scratch",
  "Acme Corp",
  "acme-corp",
  REAL_CREATED,
  REAL_EXPIRES,
  REAL_REFRESH_TOKEN,
}

local function expect_scrubbed(text)
  for _, secret in ipairs(SECRETS) do
    if text:find(secret, 1, true) then
      error("scrubbed output still contains " .. secret, 0)
    end
  end
end

local tmp, original_path

-- A fake `sf` answering `--version`, and any other command with the files
-- in $tmp/sf: stdout, stderr and code.
local function install_fake_sf(answer)
  local bin = tmp .. "/bin"
  vim.fn.mkdir(bin, "p")
  vim.fn.mkdir(tmp .. "/sf", "p")
  vim.fn.writefile({
    "#!/bin/sh",
    'echo "$*" >> "' .. tmp .. '/sf/calls"',
    'if [ "$1" = "--version" ]; then',
    '  echo "@salesforce/cli/2.108.6 linux-x64 node-v22.20.0"',
    "  exit 0",
    "fi",
    'cat "' .. tmp .. '/sf/stdout"',
    'cat "' .. tmp .. '/sf/stderr" >&2',
    'exit "$(cat "' .. tmp .. '/sf/code")"',
  }, bin .. "/sf")
  vim.fn.setfperm(bin .. "/sf", "rwxr-xr-x")
  vim.fn.writefile(vim.split(answer.stdout or "", "\n"), tmp .. "/sf/stdout", "b")
  vim.fn.writefile(vim.split(answer.stderr or "", "\n"), tmp .. "/sf/stderr", "b")
  vim.fn.writefile({ tostring(answer.code or 0) }, tmp .. "/sf/code")
  vim.env.PATH = bin .. ":" .. original_path
end

local function sf_calls()
  return vim.fn.readfile(tmp .. "/sf/calls")
end

local function read(path)
  return table.concat(vim.fn.readfile(path, "b"), "\n")
end

local OLD_FIXTURE = "-- old fixture\nreturn { recorded = false, code = 0, stdout = '{}' }\n"

local function write_old_fixture()
  vim.fn.writefile(vim.split(OLD_FIXTURE, "\n"), tmp .. "/org_display.lua", "b")
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

T["record"] = new_set()

T["record"]["writes the scrubbed org display fixture, recorded, with its sf version"] = function()
  install_fake_sf({ stdout = REAL_OUTPUT })

  local path = recorder.record({ alias = "my-scratch", dir = tmp, date = "2026-10-15" })

  eq(path, tmp .. "/org_display.lua")
  eq(sf_calls(), { "--version", "org display -o my-scratch --json" })
  local content = read(path)
  expect_scrubbed(content)
  expect.match(content, "^%-%- `sf org display %-o devhub %-%-json`\n")
  expect.match(content, "RECORDED with @salesforce/cli/2%.108%.6 on 2026%-10%-15")
  local fixture = dofile(path)
  eq(fixture.recorded, true)
  eq(fixture.code, 0)
  eq(fixture.stdout, recorder.scrub(REAL_OUTPUT))
  eq(fixture.stderr, nil)
end

T["record"]["writes identical files for the same org"] = function()
  install_fake_sf({ stdout = REAL_OUTPUT })

  local first = read(recorder.record({ alias = "my-scratch", dir = tmp, date = "2026-10-15" }))
  local second = read(recorder.record({ alias = "my-scratch", dir = tmp, date = "2026-10-15" }))

  eq(second, first)
end

T["record"]["writes a fixture the sobject refresh reads as before"] = function()
  install_fake_sf({ stdout = REAL_OUTPUT })

  local fixture = dofile(recorder.record({ alias = "my-scratch", dir = tmp, date = "2026-10-15" }))

  -- The fields tests/test_sobject.lua relies on, as in the synthetic fixture.
  local result = vim.json.decode(fixture.stdout).result
  local synthetic = vim.json.decode(helpers.sf_fixture("org_display").stdout).result
  eq(result.apiVersion, synthetic.apiVersion)
  expect.match(result.accessToken, "FAKE_ACCESS_TOKEN")
end

T["record"]["stops on a failing sf call and leaves the fixture untouched"] = function()
  install_fake_sf({
    code = 1,
    stdout = [[{"status": 1, "name": "NamedOrgNotFoundError", "message": "No authorization information found for my-scratch."}]],
  })
  write_old_fixture()

  local ok, err = pcall(recorder.record, { alias = "my-scratch", dir = tmp })

  eq(ok, false)
  eq(err, "`sf org display -o my-scratch --json` exited with 1: No authorization information found for my-scratch.")
  eq(read(tmp .. "/org_display.lua"), OLD_FIXTURE)
  eq(
    vim.fn.readdir(tmp, function(name)
      return name:match("%.tmp$") and 1 or 0
    end),
    {}
  )
end

T["record"]["stops on an error status and leaves the fixture untouched"] = function()
  install_fake_sf({ stdout = [[{"status": 1, "message": "Org expired."}]] })
  write_old_fixture()

  local ok, err = pcall(recorder.record, { alias = "my-scratch", dir = tmp })

  eq(ok, false)
  eq(err, "`sf org display -o my-scratch --json` returned status 1: Org expired.")
  eq(read(tmp .. "/org_display.lua"), OLD_FIXTURE)
end

T["record"]["stops on output that isn't JSON and leaves the fixture untouched"] = function()
  install_fake_sf({ stdout = "Error: something went wrong\n", stderr = "" })
  write_old_fixture()

  local ok, err = pcall(recorder.record, { alias = "my-scratch", dir = tmp })

  eq(ok, false)
  expect.match(err, "^`sf org display %-o my%-scratch %-%-json` output can't be recorded: not JSON")
  eq(read(tmp .. "/org_display.lua"), OLD_FIXTURE)
end

T["command"] = new_set()

local function run_script(alias)
  local argv = { vim.v.progpath, "-l", "scripts/record_fixture.lua" }
  if alias then
    vim.list_extend(argv, { alias, tmp })
  end
  return vim.system(argv, { text = true }):wait()
end

T["command"]["records the fixture given an org alias"] = function()
  install_fake_sf({ stdout = REAL_OUTPUT })

  local result = run_script("my-scratch")

  eq(result.code, 0)
  eq(result.stdout, "Recorded " .. tmp .. "/org_display.lua\n")
  local fixture = dofile(tmp .. "/org_display.lua")
  eq(fixture.recorded, true)
  expect_scrubbed(read(tmp .. "/org_display.lua"))
end

T["command"]["exits non-zero with a clear message when sf fails"] = function()
  install_fake_sf({ code = 1, stdout = "", stderr = "sf: command exploded" })
  write_old_fixture()

  local result = run_script("my-scratch")

  eq(result.code, 1)
  eq(
    result.stderr,
    "record_fixture: `sf org display -o my-scratch --json` exited with 1: sf: command exploded\n"
      .. "The existing fixture was left untouched.\n"
  )
  eq(read(tmp .. "/org_display.lua"), OLD_FIXTURE)
end

T["command"]["asks for an org alias"] = function()
  local result = run_script(nil)

  eq(result.code, 2)
  expect.match(result.stderr, "^usage: ")
end

return T
