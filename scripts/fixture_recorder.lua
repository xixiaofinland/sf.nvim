-- Records the fixtures of the sf fake in tests/sf_fake.lua from a throwaway
-- scratch org. Run it through scripts/record_fixtures.lua (`make
-- record-fixtures DEVHUB=<alias>`); tests load it with `dofile` to drive it
-- against a fake `sf` on PATH.
--
-- Scrubbing is deterministic: every sensitive value becomes a fixed
-- placeholder, numbered in a stable order, and values that change on every
-- run (durations, test run ids, timestamps, record ids, response headers) are
-- normalised, so re-recording gives the same fixtures unless the CLI's output
-- changed.

local M = {}

M.root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
M.fixtures_dir = M.root .. "/tests/fixtures/sf"

-- The alias the recorder gives the scratch org it creates.
M.SCRATCH_ALIAS = "sf-nvim-fixtures"

-- ── Scrubbing

-- The tests pin the describe URL to this version. It moves with every
-- Salesforce release, which is no change in the CLI's output shape.
local API_VERSION = "62.0"

-- Response headers (dates, API usage, cookies) change on every call.
local HEADER_PLACEHOLDER = "FAKE_HEADER_VALUE"

---@param value string
---@return boolean
local function is_sf_id(value)
  return (#value == 15 or #value == 18) and value:match("^%w+$") ~= nil and value:match("%d") ~= nil
end

---@param value string
---@return boolean
local function is_iso_timestamp(value)
  return value:match("^%d%d%d%d%-%d%d%-%d%d") ~= nil
end

-- As in `instanceApiVersionLastRetrieved`: "10/14/2026, 9:31:27 AM".
---@param value string
---@return boolean
local function is_local_timestamp(value)
  return value:match("^%d%d?/%d%d?/%d%d%d%d") ~= nil
end

---@param value string
---@return boolean
local function is_email(value)
  return value:match("^[^%s@]+@[^%s@]+%.%a+$") ~= nil
end

---@param value string
---@return boolean
local function is_url(value)
  return value:match("^https?://") ~= nil
end

---@param value string
---@return string
local function host_of(value)
  return value:match("^https?://([^/:]+)")
end

-- Numbers under these keys are durations in ms, such as `RunTime`.
---@param key string
---@return boolean
local function is_duration_key(key)
  return key:match("Time$") ~= nil or key:match("TimeInMs$") ~= nil
end

-- Each kind numbers its distinct originals from 1.
local placeholder = {
  password = function(n)
    return "FAKE_PASSWORD_" .. n
  end,
  auth_url = function(n)
    return string.format("force://PlatformCLI::FAKE_REFRESH_TOKEN_%d@fake-company.my.salesforce.com", n)
  end,
  username = function(n)
    return n == 1 and "admin@example.com" or string.format("user%d@example.com", n)
  end,
  url = function(n)
    return n == 1 and "https://fake-company.my.salesforce.com"
      or string.format("https://fake-company-%d.my.salesforce.com", n)
  end,
  alias = function(n)
    return n == 1 and "devhub" or "alias" .. n
  end,
  org_name = function(n)
    return n == 1 and "Fake Company" or "Fake Company " .. n
  end,
  person = function(n)
    return n == 1 and "Fake Admin" or "Fake User " .. n
  end,
  client_id = function(n)
    return "FAKE_CLIENT_ID_" .. n
  end,
}

-- Paths sf prints, such as a JWT key file or a stack trace, start with it.
local HOME_PLACEHOLDER = "/home/user"

---@param key string
---@param value string
---@param parent table|nil The table holding the value
---@return string|nil kind
local function kind_of(key, value, parent)
  if key == "accessToken" or key == "refreshToken" then
    return "token"
  elseif key == "password" then
    return "password"
  elseif key == "sfdxAuthUrl" then
    return "auth_url"
  elseif key == "alias" then
    return "alias"
  elseif key == "orgName" or (key == "name" and parent and parent.orgId) then
    return "org_name"
  elseif key == "clientId" and value ~= "PlatformCLI" then
    return "client_id"
  elseif key:match("ByName$") then
    return "person"
  elseif (key == "id" or key:match("Id$")) and is_sf_id(value) then
    return "id"
  elseif is_iso_timestamp(value) or is_local_timestamp(value) then
    return "timestamp"
  elseif key:lower():match("username$") or key == "createdBy" or is_email(value) then
    return "username"
  elseif is_url(value) then
    return "url"
  end
end

-- Visited first, so the org's own id, user and URL get placeholder 1.
local FIRST_KEYS = { id = 1, username = 2, instanceUrl = 3 }

---@param value any
---@param visit fun(key: string, value: string, parent: table|nil)
---@param key string|nil
---@param parent table|nil
local function walk(value, visit, key, parent)
  if type(value) == "string" then
    visit(key or "", value, parent)
  elseif type(value) == "table" then
    local keys = vim.tbl_keys(value)
    table.sort(keys, function(a, b)
      local rank_a, rank_b = FIRST_KEYS[a] or math.huge, FIRST_KEYS[b] or math.huge
      if rank_a ~= rank_b then
        return rank_a < rank_b
      end
      if type(a) == "number" and type(b) == "number" then
        return a < b
      end
      return tostring(a) < tostring(b)
    end)
    for _, k in ipairs(keys) do
      -- Array items inherit their parent's key.
      walk(value[k], visit, type(k) == "string" and k or key, value)
    end
  end
end

---@param value string
---@return string
local function normalise_timestamp(value)
  if is_iso_timestamp(value) then
    return "2026-01-01" .. value:sub(11):gsub("%d", "0")
  end
  -- The hour has one digit or two, depending on when the recording ran.
  local rest = value:gsub("^%d+/%d+/%d+", ""):gsub("^, %d+:", ", 0:"):gsub("%d", "0"):gsub("[AP]M", "AM")
  return "1/1/2026" .. rest
end

-- Shorter originals (an alias, an API version) are replaced only as whole
-- words, so an alias "on" can't turn "Connected" into something else.
local MIN_SUBSTRING = 8

---@param text string
---@param original string
---@param init integer
---@return integer|nil start Of the next occurrence that counts as a match
local function find_original(text, original, init)
  local start = text:find(original, init, true)
  while start and #original < MIN_SUBSTRING do
    local before = text:sub(start - 1, start - 1)
    local after = text:sub(start + #original, start + #original + 1)
    -- A "." ending a sentence is a boundary; one inside "a.b" is not.
    if not before:match("[%w_%-%.@]") and not after:match("^[%w_%-@]") and not after:match("^%.%w") then
      return start
    end
    start = text:find(original, start + 1, true)
  end
  return start
end

---@alias Replacement { original: string, scrubbed: string }

---@param text string
---@param replacements Replacement[]
---@return string
local function replace_text(text, replacements)
  for _, r in ipairs(replacements) do
    local parts, pos = {}, 1
    local start = find_original(text, r.original, pos)
    while start do
      table.insert(parts, text:sub(pos, start - 1))
      table.insert(parts, r.scrubbed)
      pos = start + #r.original
      start = find_original(text, r.original, pos)
    end
    table.insert(parts, text:sub(pos))
    text = table.concat(parts)
  end
  return text
end

---@param text string
---@param replacements Replacement[]
---@return string[] originals Those still found in `text`
local function leftovers(text, replacements)
  local left = {}
  for _, r in ipairs(replacements) do
    if find_original(text, r.original, 1) then
      table.insert(left, r.original)
    end
  end
  return left
end

---@param json string
---@param open integer Position of a string's opening quote
---@return integer close Position of its closing quote
local function string_end(json, open)
  local close = open + 1
  while true do
    local c = json:sub(close, close)
    if c == "" then
      error("unterminated JSON string", 0)
    elseif c == "\\" then
      close = close + 2
    elseif c == '"' then
      return close
    else
      close = close + 1
    end
  end
end

--- Calls `fn` for every string and number value of raw JSON text and puts
--- what it returns, if anything, in the value's place; keys and layout stay as
--- they were. `path` holds the keys leading to the value; array items add
--- none, so they share their array's key.
---@param json string
---@param fn fun(path: string[], value: string, is_string: boolean): string|nil
---@return string
local function map_json_values(json, fn)
  local out = {}
  local containers = {} -- "{" or "[" for each open container
  local keys = {} -- the key each open container is the value of, or false
  local key -- the last key read in the innermost object
  local pos = 1 -- the first character not copied to `out` yet

  local function path()
    local p = {}
    for _, k in ipairs(keys) do
      if k then
        table.insert(p, k)
      end
    end
    if containers[#containers] == "{" and key then
      table.insert(p, key)
    end
    return p
  end

  local i = json:find('[%"{}%[%]%-%d]')
  while i do
    local c = json:sub(i, i)
    if c == '"' then
      local close = string_end(json, i)
      local content = json:sub(i + 1, close - 1)
      if containers[#containers] == "{" and json:find("^%s*:", close + 1) then
        key = content
      else
        local new = fn(path(), content, true)
        if new and new ~= content then
          table.insert(out, json:sub(pos, i))
          table.insert(out, new)
          pos = close
        end
      end
      i = close + 1
    elseif c == "{" or c == "[" then
      table.insert(keys, containers[#containers] == "{" and key or false)
      table.insert(containers, c)
      key = nil
      i = i + 1
    elseif c == "}" or c == "]" then
      table.remove(containers)
      key = table.remove(keys) or nil
      i = i + 1
    else
      local number = json:match("^%-?[%d%.eE%+%-]+", i)
      local new = fn(path(), number, false)
      if new and new ~= number then
        table.insert(out, json:sub(pos, i - 1))
        table.insert(out, new)
        pos = i + #number
      end
      i = i + #number
    end
    i = json:find('[%"{}%[%]%-%d]', i)
  end
  table.insert(out, json:sub(pos))
  return table.concat(out)
end

-- Durations in human-readable test output: "52 ms" in the summary and the
-- RUNTIME (MS) column of the results table.
---@param text string
---@return string
local function normalise_human_durations(text)
  local lines = vim.split(text, "\n", { plain = true })
  local in_runtime_table = false
  for i, line in ipairs(lines) do
    if line:match("RUNTIME %(MS%)%s*$") then
      in_runtime_table = true
    elseif vim.trim(line) == "" then
      in_runtime_table = false
    elseif in_runtime_table and not line:match("^─") then
      line = line:gsub("(%s)%d+(%s*)$", "%10%2")
    end
    lines[i] = line:gsub("%d+ ms", "0 ms")
  end
  return table.concat(lines, "\n")
end

---@class Scrubber
---@field by_original table<string, string>
---@field counts table<string, integer>
---@field id_counts table<string, integer>
local Scrubber = {}
Scrubber.__index = Scrubber

--- A scrubber remembers the placeholder of every value it has replaced, so
--- the fixtures of one recording share them: the org id in `org display` and
--- in `apex get test` is the same placeholder.
---@return Scrubber
M.new_scrubber = function()
  local scrubber = setmetatable({ by_original = {}, counts = {}, id_counts = {} }, Scrubber)
  scrubber:add(vim.uv.os_homedir(), HOME_PLACEHOLDER)
  return scrubber
end

---@param original string
---@param scrubbed string
function Scrubber:add(original, scrubbed)
  if original ~= "" and original ~= scrubbed and not self.by_original[original] then
    self.by_original[original] = scrubbed
  end
end

--- Gives an alias the recorder knows up front its placeholder (by default the
--- next numbered one): sf may name an alias without returning an alias field.
---@param original string
---@param scrubbed string|nil
function Scrubber:alias(original, scrubbed)
  self.counts.alias = (self.counts.alias or 0) + 1
  self:add(original, scrubbed or placeholder.alias(self.counts.alias))
end

--- Ids keep their 3-character key prefix. The 15- and 18-character forms of
--- one id get matching placeholders, whichever is seen first.
---@param value string
---@return string
function Scrubber:id(value)
  local short = value:sub(1, 15)
  local fake = self.by_original[short]
  if not fake then
    local prefix = value:sub(1, 3)
    self.id_counts[prefix] = (self.id_counts[prefix] or 0) + 1
    fake = string.format("%s%012d", prefix, self.id_counts[prefix])
    self:add(short, fake)
  end
  self:add(value, (fake .. "AAA"):sub(1, #value))
  return self.by_original[value] or value
end

---@param decoded any Decoded `sf --json` output
function Scrubber:collect(decoded)
  -- Ids first, so a token's org id prefix gets the org id's placeholder.
  walk(decoded, function(key, value)
    if kind_of(key, value) == "id" then
      self:id(value)
    end
  end)

  walk(decoded, function(key, value, parent)
    if self.by_original[value] then
      return
    end
    if key == "apiVersion" or key == "instanceApiVersion" then
      return self:add(value, API_VERSION)
    end
    local kind = kind_of(key, value, parent)
    if not kind or kind == "id" then
      return
    end
    if kind == "token" then
      self.counts.token = (self.counts.token or 0) + 1
      -- An access token starts with the 15-character org id and a "!".
      local org_id = value:match("^(%w+)!")
      local prefix = org_id and is_sf_id(org_id) and self:id(org_id):sub(1, 15) or "00D000000000000"
      self:add(value, string.format("%s!FAKE_ACCESS_TOKEN_%d", prefix, self.counts.token))
    elseif kind == "timestamp" then
      self:add(value, normalise_timestamp(value))
    else
      self.counts[kind] = (self.counts[kind] or 0) + 1
      self:add(value, placeholder[kind](self.counts[kind]))
      if kind == "url" or kind == "auth_url" then
        local host = host_of(value)
        if host then
          self:add(host, host_of(self.by_original[value]))
        end
      end
    end
  end)
end

---@return Replacement[] replacements Longest original first
function Scrubber:replacements()
  local replacements = {}
  for original, scrubbed in pairs(self.by_original) do
    table.insert(replacements, { original = original, scrubbed = scrubbed })
  end
  table.sort(replacements, function(a, b)
    if #a.original ~= #b.original then
      return #a.original > #b.original
    end
    return a.original < b.original
  end)
  return replacements
end

--- Scrubs `sf --json` output, keeping the CLI's formatting. Every occurrence
--- of a sensitive value is replaced, also inside other strings such as
--- warnings, and in `extra` (e.g. stderr).
---@param stdout string `sf --json` output
---@param extra string|nil Other output of the same call to scrub alike
---@return string scrubbed_stdout
---@return string|nil scrubbed_extra
function Scrubber:json(stdout, extra)
  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok then
    error("not JSON: " .. tostring(decoded), 0)
  end
  self:collect(decoded)
  local replacements = self:replacements()

  local scrubbed = map_json_values(stdout, function(path, value, is_string)
    local key = path[#path] or ""
    if not is_string then
      return is_duration_key(key) and "0" or nil
    elseif path[#path - 1] == "headers" and key ~= "content-type" then
      return HEADER_PLACEHOLDER
    elseif value:match("^%d+ ms$") then
      return "0 ms"
    end
    return replace_text(value, replacements)
  end)
  extra = extra and replace_text(extra, replacements)

  -- A value JSON-escaped in the raw text (a quote, a backslash) wouldn't
  -- have been found; refuse to write it rather than leak it.
  local left = extra and leftovers(extra, replacements) or {}
  walk(vim.json.decode(scrubbed), function(_, value)
    vim.list_extend(left, leftovers(value, replacements))
  end)
  if #left > 0 then
    error("scrubbing left original values in the output: " .. table.concat(left, ", "), 0)
  end

  return scrubbed, extra
end

--- Scrubs human-readable output, such as `sf apex run test -r human`, of the
--- values seen so far in JSON output, its test run id and its durations.
---@param text string
---@return string
function Scrubber:text(text)
  for id in text:gmatch("Test Run Id%s+(%w+)") do
    if is_sf_id(id) then
      self:id(id)
    end
  end
  return normalise_human_durations(replace_text(text, self:replacements()))
end

--- Scrubs one call's `sf --json` output with a scrubber of its own.
---@param stdout string `sf --json` output
---@param extra string|nil Other output of the same call to scrub alike
---@param alias string|nil The org alias the command was given, scrubbed too
---@return string scrubbed_stdout
---@return string|nil scrubbed_extra
M.scrub = function(stdout, extra, alias)
  local scrubber = M.new_scrubber()
  if alias then
    scrubber:alias(alias)
  end
  return scrubber:json(stdout, extra)
end

-- ── The scratch org's project

-- One class and its test class, enough for test runs and coverage. The names
-- match the synthetic fixtures and tests/test_coverage.lua; one method stays
-- uncovered so coverage has both kinds of line.
local CLASS_META = [[
<?xml version="1.0" encoding="UTF-8"?>
<ApexClass xmlns="http://soap.sforce.com/2006/04/metadata">
    <apiVersion>62.0</apiVersion>
    <status>Active</status>
</ApexClass>
]]

M.PROJECT_FILES = {
  ["sfdx-project.json"] = [[
{
  "packageDirectories": [{ "path": "force-app", "default": true }],
  "name": "sf-nvim-fixtures",
  "namespace": "",
  "sfdcLoginUrl": "https://login.salesforce.com"
}
]],
  ["config/project-scratch-def.json"] = [[
{
  "orgName": "sf.nvim fixtures",
  "edition": "Developer",
  "hasSampleData": false
}
]],
  ["force-app/main/default/classes/SfProject.cls"] = [[
public with sharing class SfProject {
    public String name;

    public SfProject(String name) {
        this.name = name;
    }

    public String greeting() {
        return name == null ? 'Hello' : 'Hello, ' + name;
    }

    public Integer neverCalled() {
        return 0;
    }
}
]],
  ["force-app/main/default/classes/SfProject.cls-meta.xml"] = CLASS_META,
  ["force-app/main/default/classes/SfProjectTest.cls"] = [[
@IsTest
private class SfProjectTest {
    @IsTest
    static void constructsWithName() {
        Assert.areEqual('Hello, Ada', new SfProject('Ada').greeting());
    }

    @IsTest
    static void constructsWithNull() {
        Assert.areEqual('Hello', new SfProject(null).greeting());
    }
}
]],
  ["force-app/main/default/classes/SfProjectTest.cls-meta.xml"] = CLASS_META,
  -- A folder-based type: listing it needs the folder (#300)
  ["force-app/main/default/email/SfNvimTemplates.emailFolder-meta.xml"] = [[
<?xml version="1.0" encoding="UTF-8"?>
<EmailFolder xmlns="http://soap.sforce.com/2006/04/metadata">
    <accessType>Public</accessType>
    <name>SfNvimTemplates</name>
    <publicFolderAccess>ReadWrite</publicFolderAccess>
</EmailFolder>
]],
  ["force-app/main/default/email/SfNvimTemplates/Welcome.email"] = "Hello {!Contact.FirstName}\n",
  ["force-app/main/default/email/SfNvimTemplates/Welcome.email-meta.xml"] = [[
<?xml version="1.0" encoding="UTF-8"?>
<EmailTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
    <available>true</available>
    <encodingKey>UTF-8</encodingKey>
    <name>Welcome</name>
    <style>none</style>
    <subject>Welcome</subject>
    <type>text</type>
    <uiType>Aloha</uiType>
</EmailTemplate>
]],
}

---@param dir string
M.write_project = function(dir)
  for path, content in pairs(M.PROJECT_FILES) do
    local full = dir .. "/" .. path
    vim.fn.mkdir(vim.fn.fnamemodify(full, ":h"), "p")
    vim.fn.writefile(vim.split(content, "\n", { plain = true }), full, "b")
  end
end

-- ── Running sf

-- No update notice or colour codes in what gets recorded. The signup app is
-- the CLI's own: signup can't copy a Dev Hub's External Client App into the
-- scratch org and fails with C-1016, and PlatformCLI works for any Dev Hub.
local SF_ENV = {
  SF_SKIP_NEW_VERSION_CHECK = "true",
  FORCE_COLOR = "0",
  NO_COLOR = "1",
  SF_SCRATCH_SIGNUP_CONNECTED_APP = "PlatformCLI",
  SF_SCRATCH_SIGNUP_CALLBACK_URL = "http://localhost:1717/OauthRedirect",
}

---@param argv string[]
---@param cwd string|nil
---@return vim.SystemCompleted
local function run(argv, cwd)
  local ok, result = pcall(function()
    return vim.system(argv, { text = true, cwd = cwd, env = SF_ENV }):wait()
  end)
  if not ok then
    error(string.format("could not run `%s`: %s", table.concat(argv, " "), result), 0)
  end
  return result
end

---@param result vim.SystemCompleted
---@return string
local function failure_detail(result)
  local ok, decoded = pcall(vim.json.decode, result.stdout or "")
  if ok and type(decoded) == "table" and decoded.message then
    return decoded.message
  end
  local text = vim.trim((result.stderr or "") ~= "" and result.stderr or (result.stdout or ""))
  return text ~= "" and text or "no output"
end

--- Runs an sf command and raises an error unless it succeeded or, with
--- `fails`, unless it failed.
---@param argv string[]
---@param opts { cwd: string|nil, fails: boolean|nil }|nil
---@return vim.SystemCompleted
local function sf(argv, opts)
  opts = opts or {}
  local cmd = table.concat(argv, " ")
  local result = run(argv, opts.cwd)
  if opts.fails then
    if result.code == 0 then
      error(string.format("`%s` was expected to fail but exited with 0", cmd), 0)
    end
    return result
  end
  local decoded_ok, decoded = pcall(vim.json.decode, result.stdout or "")
  local status = decoded_ok and type(decoded) == "table" and decoded.status or 0
  if result.code ~= 0 then
    error(string.format("`%s` exited with %d: %s", cmd, result.code, failure_detail(result)), 0)
  elseif status ~= 0 then
    error(string.format("`%s` returned status %s: %s", cmd, status, failure_detail(result)), 0)
  end
  return result
end

---@return string e.g. "@salesforce/cli/2.60.0"
local function sf_version()
  local result = sf({ "sf", "--version" })
  local version = (result.stdout or ""):match("^%s*(%S+)")
  if not version then
    error("`sf --version` printed no version", 0)
  end
  return version
end

-- ── Fixtures

-- sObjects in the describe batch; the last one doesn't exist, so the batch
-- holds a failed sub-request as well.
M.DESCRIBE_NAMES = { "Account", "Contact", "NoSuchObject__c" }

-- A well-formed test run id no run has.
local MISSING_TEST_RUN_ID = "707000000000000"

---@class FixtureContext
---@field scratch string The scratch org's alias
---@field cwd string The project directory
---@field api_version string|nil From `org display`
---@field body_file string|nil The describe batch's request body
---@field test_run_id string|nil From the human-readable test run

---@class FixtureSpec
---@field name string File name in the fixtures dir, without ".lua"
---@field note string What the fixture is for, in its header
---@field argv fun(ctx: FixtureContext): string[]
---@field human boolean|nil Output isn't JSON
---@field fails boolean|nil The command is meant to fail
---@field after fun(ctx: FixtureContext, result: vim.SystemCompleted, scrubber: Scrubber)|nil

-- The describe batch of M.DESCRIBE_NAMES, as the sObject refresh sends it.
---@param ctx FixtureContext
---@param extra string[] Flags before `-o`
---@return string[]
local function describe_batch_argv(ctx, extra)
  if not ctx.body_file then
    local requests = {}
    for _, name in ipairs(M.DESCRIBE_NAMES) do
      table.insert(requests, { method = "GET", url = "v" .. ctx.api_version .. "/sobjects/" .. name .. "/describe" })
    end
    ctx.body_file = vim.fn.tempname() .. ".json"
    vim.fn.writefile({ vim.json.encode({ batchRequests = requests }) }, ctx.body_file)
  end
  local argv = { "sf", "api", "request", "rest", "services/data/v" .. ctx.api_version .. "/composite/batch" }
  vim.list_extend(argv, { "--method", "POST", "--body", "@" .. ctx.body_file })
  vim.list_extend(argv, extra)
  return vim.list_extend(argv, { "-o", ctx.scratch, "--json" })
end

-- In recording order: org display gives the API version the describes use,
-- the human-readable test run the id `apex get test` reads.
---@type FixtureSpec[]
M.FIXTURES = {
  {
    name = "org_display",
    note = "Its access token and API version feed the sObject refresh.",
    argv = function(ctx)
      return { "sf", "org", "display", "-o", ctx.scratch, "--json" }
    end,
    after = function(ctx, result, scrubber)
      local version = vim.json.decode(result.stdout).result.apiVersion
      if type(version) ~= "string" then
        error("`sf org display` returned no apiVersion", 0)
      end
      ctx.api_version = version
      scrubber:add("data/v" .. version, "data/v" .. API_VERSION)
    end,
  },
  {
    name = "org_list",
    note = "Every org this machine is authorised to, scrubbed; the scratch org is my-scratch, the project's default target org, and the Dev Hub devhub.",
    argv = function()
      return { "sf", "org", "list", "--json", "--skip-connection-status" }
    end,
  },
  {
    name = "sobject_list",
    note = "The names the sObject refresh describes.",
    argv = function(ctx)
      return { "sf", "sobject", "list", "-o", ctx.scratch, "-s", "ALL", "--json" }
    end,
  },
  {
    name = "api_request_rest_composite_batch",
    note = "The describe batch the sObject refresh sends, for "
      .. table.concat(M.DESCRIBE_NAMES, ", ")
      .. "; the last one doesn't exist, so its sub-request failed.",
    argv = function(ctx)
      return describe_batch_argv(ctx, {})
    end,
  },
  {
    name = "api_request_rest_401",
    note = "The describe batch with a session Salesforce rejects: the header overrides the token sf sends.",
    fails = true,
    argv = function(ctx)
      return describe_batch_argv(ctx, { "--header", "Authorization: Bearer 00D000000000000!NOT_A_SESSION" })
    end,
    -- Any other failure, such as a network error, isn't this fixture.
    after = function(_, result)
      local ok, decoded = pcall(vim.json.decode, result.stdout or "")
      local status = ok and type(decoded) == "table" and type(decoded.result) == "table" and decoded.result.statusCode
      if status ~= 401 then
        local got = status and ("HTTP " .. tostring(status)) or "no HTTP response"
        error(
          string.format("the describe batch with a bad session got %s, not 401: %s", got, failure_detail(result)),
          0
        )
      end
    end,
  },
  {
    name = "apex_run_test_human",
    note = "The form the plugin runs in its terminal; it reads the Test Run Id line to fetch coverage.",
    human = true,
    argv = function(ctx)
      return { "sf", "apex", "run", "test", "-n", "SfProjectTest", "-r", "human", "-w", "5", "-c", "-o", ctx.scratch }
    end,
    after = function(ctx, result)
      ctx.test_run_id = (result.stdout or ""):match("Test Run Id%s+(%w+)")
      if not ctx.test_run_id then
        error("`sf apex run test -r human` printed no Test Run Id", 0)
      end
    end,
  },
  {
    name = "apex_get_test_coverage",
    note = "Coverage of the run above, which the plugin saves as sf_cache/test_result.json to place coverage signs.",
    argv = function(ctx)
      return { "sf", "apex", "get", "test", "-i", ctx.test_run_id, "-c", "--json", "-o", ctx.scratch }
    end,
  },
  {
    name = "apex_run_test",
    note = "A second run of the same tests, reported as JSON; its test run id differs from the human run's.",
    argv = function(ctx)
      return { "sf", "apex", "run", "test", "-n", "SfProjectTest", "-w", "5", "-c", "--json", "-o", ctx.scratch }
    end,
  },
  {
    name = "apex_get_test_error",
    note = "`apex get test` failing: the error payload carries no coverage.",
    fails = true,
    argv = function(ctx)
      return { "sf", "apex", "get", "test", "-i", MISSING_TEST_RUN_ID, "-c", "--json", "-o", ctx.scratch }
    end,
  },
  {
    name = "org_list_metadata",
    note = "The org's Apex classes, as the metadata picker lists them.",
    argv = function(ctx)
      return { "sf", "org", "list", "metadata", "-m", "ApexClass", "-o", ctx.scratch, "--json" }
    end,
  },
  {
    name = "org_list_metadata_email_folder",
    note = "The org's email template folders, which the metadata pull lists before their templates.",
    argv = function(ctx)
      return { "sf", "org", "list", "metadata", "-m", "EmailFolder", "-o", ctx.scratch, "--json" }
    end,
  },
  {
    name = "org_list_metadata_email_template_folder",
    note = "The email templates in one folder.",
    argv = function(ctx)
      return {
        "sf",
        "org",
        "list",
        "metadata",
        "-m",
        "EmailTemplate",
        "--folder",
        "SfNvimTemplates",
        "-o",
        ctx.scratch,
        "--json",
      }
    end,
  },
  {
    name = "org_list_metadata_email_template_unfiled",
    note = "The email templates in no folder, which the folder list names unfiled$public.",
    argv = function(ctx)
      return {
        "sf",
        "org",
        "list",
        "metadata",
        "-m",
        "EmailTemplate",
        "--folder",
        "unfiled$public",
        "-o",
        ctx.scratch,
        "--json",
      }
    end,
  },
}

---@param text string
---@return string
local function long_string(text)
  local level = ""
  while text:find("]" .. level .. "]", 1, true) do
    level = level .. "="
  end
  return string.format("[%s[\n%s]%s]", level, text, level)
end

---@param text string
---@param width integer
---@return string[]
local function comment_lines(text, width)
  local lines, line = {}, "--"
  for word in text:gmatch("%S+") do
    if #line + 1 + #word > width and line ~= "--" then
      table.insert(lines, line)
      line = "--"
    end
    line = line .. " " .. word
  end
  table.insert(lines, line)
  return lines
end

---@param fixture { shown: string, note: string|nil, sf_version: string, date: string, code: integer, stdout: string, stderr: string|nil }
---@return string
M.render = function(fixture)
  local lines = { string.format("-- `%s`", fixture.shown), "--" }
  if fixture.note then
    vim.list_extend(lines, comment_lines(fixture.note, 80))
    table.insert(lines, "--")
  end
  vim.list_extend(lines, {
    string.format("-- RECORDED with %s on %s by scripts/record_fixtures.lua, which", fixture.sf_version, fixture.date),
    "-- replaced tokens, ids, usernames, URLs, timestamps and durations with placeholders.",
    "-- Re-record with `make record-fixtures DEVHUB=<alias>` instead of editing it.",
    "return {",
    "  recorded = true,",
    string.format("  code = %d,", fixture.code),
    string.format("  stdout = %s,", long_string(fixture.stdout)),
  })
  if fixture.stderr and fixture.stderr ~= "" then
    table.insert(lines, string.format("  stderr = %s,", long_string(fixture.stderr)))
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

---@param spec FixtureSpec
---@param ctx FixtureContext
---@param scrubber Scrubber
---@return { shown: string, note: string, code: integer, stdout: string, stderr: string|nil }
local function record_one(spec, ctx, scrubber)
  local argv = spec.argv(ctx)
  local cmd = table.concat(argv, " ")
  local result = sf(argv, { cwd = ctx.cwd, fails = spec.fails })
  if spec.after then
    spec.after(ctx, result, scrubber)
  end

  local ok, stdout, stderr = pcall(function()
    if spec.human then
      return scrubber:text(result.stdout or ""), result.stderr and scrubber:text(result.stderr)
    end
    return scrubber:json(result.stdout or "", result.stderr)
  end)
  if not ok then
    error(string.format("`%s` output can't be recorded: %s", cmd, stdout), 0)
  end
  local shown = ctx.body_file and cmd:gsub(vim.pesc(ctx.body_file), "<file>") or cmd
  return {
    shown = scrubber:text(shown),
    note = spec.note,
    code = result.code,
    stdout = stdout,
    stderr = stderr,
  }
end

--- Writes every file aside first and renames them into place, so a failed
--- write leaves the old fixtures whole.
---@param files { path: string, content: string }[]
local function write_all(files)
  for i, f in ipairs(files) do
    local tmp = f.path .. ".tmp"
    local file, open_err = io.open(tmp, "w")
    if file then
      file:write(f.content)
      file:close()
    else
      for j = 1, i - 1 do
        os.remove(files[j].path .. ".tmp")
      end
      error("can't write " .. tmp .. ": " .. tostring(open_err), 0)
    end
  end
  for _, f in ipairs(files) do
    local renamed, rename_err = os.rename(f.path .. ".tmp", f.path)
    if not renamed then
      error("can't replace " .. f.path .. ": " .. tostring(rename_err), 0)
    end
  end
end

local UNTOUCHED = "\nThe existing fixtures were left untouched."

--- Creates one scratch org from the Dev Hub, deploys M.PROJECT_FILES to it,
--- records every fixture in M.FIXTURES, scrubbed, and deletes the org, also
--- when a step in between failed. The org is created exactly once: Developer
--- Edition Dev Hubs allow only a few a day. Fixtures are written only when
--- every step succeeded; otherwise it raises an error and leaves them as they
--- were.
---@param opts { devhub: string, dir: string|nil, date: string|nil }
---@return string[] paths The fixtures written
M.record = function(opts)
  assert(opts.devhub and opts.devhub ~= "", "a Dev Hub alias is required")
  local dir = opts.dir or M.fixtures_dir
  local scratch = M.SCRATCH_ALIAS

  local ok_version, version = pcall(sf_version)
  if not ok_version then
    error(version .. UNTOUCHED, 0)
  end

  local project = vim.fn.tempname()
  M.write_project(project)
  local scrubber = M.new_scrubber()
  scrubber:alias(opts.devhub, "devhub")
  scrubber:alias(scratch, "my-scratch")
  local ctx = { scratch = scratch, cwd = project }

  local recorded = {}
  local ok, err = pcall(function()
    sf({
      "sf",
      "org",
      "create",
      "scratch",
      "--target-dev-hub",
      opts.devhub,
      "--alias",
      scratch,
      -- As in a user's project, so `org list` shows a default target org.
      "--set-default",
      "--definition-file",
      "config/project-scratch-def.json",
      "--duration-days",
      "1",
      "--wait",
      "15",
      "--json",
    }, { cwd = project })
    sf(
      { "sf", "project", "deploy", "start", "--source-dir", "force-app", "-o", scratch, "--wait", "15", "--json" },
      { cwd = project }
    )
    for _, spec in ipairs(M.FIXTURES) do
      recorded[spec.name] = record_one(spec, ctx, scrubber)
    end
  end)

  -- Also after a failed create: one that timed out may have made the org.
  local deleted, delete_err = pcall(
    sf,
    { "sf", "org", "delete", "scratch", "-o", scratch, "--no-prompt", "--json" },
    { cwd = project }
  )
  local delete_failure = not deleted
    and string.format("%s\nDelete it by hand with `sf org delete scratch -o %s --no-prompt`.", delete_err, scratch)
  local delete_note = delete_failure and ("\nDeleting the scratch org failed too: " .. delete_failure) or ""
  if ctx.body_file then
    vim.fn.delete(ctx.body_file)
  end
  vim.fn.delete(project, "rf")

  if not ok then
    error(err .. UNTOUCHED .. delete_note, 0)
  end

  local files = {}
  for _, spec in ipairs(M.FIXTURES) do
    local fixture = recorded[spec.name]
    fixture.sf_version = version
    fixture.date = opts.date or os.date("!%Y-%m-%d")
    table.insert(files, { path = dir .. "/" .. spec.name .. ".lua", content = M.render(fixture) })
  end
  local written, write_err = pcall(write_all, files)
  if not written then
    error(write_err .. UNTOUCHED .. delete_note, 0)
  end

  if delete_failure then
    error("The fixtures were recorded, but deleting the scratch org failed: " .. delete_failure, 0)
  end
  return vim.tbl_map(function(f)
    return f.path
  end, files)
end

return M
