-- Records `sf --json` output as fixtures for the sf fake in tests/sf_fake.lua.
-- Run it through scripts/record_fixture.lua (`make record-fixture ORG=<alias>`);
-- tests load it with `dofile` to drive it against a fake `sf` on PATH.
--
-- Scrubbing is deterministic: every sensitive value becomes a fixed
-- placeholder, numbered in a stable order, so recording the same org twice
-- gives byte-identical fixtures and any diff means the CLI's output changed.

local M = {}

M.root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
M.fixtures_dir = M.root .. "/tests/fixtures/sf"

-- ── Scrubbing

-- The tests pin the describe URL to this version. It moves with every
-- Salesforce release, which is no change in the CLI's output shape.
local API_VERSION = "62.0"

---@param value string
---@return boolean
local function is_sf_id(value)
  return (#value == 15 or #value == 18) and value:match("^%w+$") ~= nil and value:match("%d") ~= nil
end

---@param value string
---@return boolean
local function is_timestamp(value)
  return value:match("^%d%d%d%d%-%d%d%-%d%d") ~= nil
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
}

---@param key string
---@param value string
---@return string|nil kind
local function kind_of(key, value)
  if key == "accessToken" or key == "refreshToken" then
    return "token"
  elseif key == "password" then
    return "password"
  elseif key == "sfdxAuthUrl" then
    return "auth_url"
  elseif key == "alias" then
    return "alias"
  elseif key == "orgName" then
    return "org_name"
  elseif (key == "id" or key:match("Id$")) and is_sf_id(value) then
    return "id"
  elseif is_timestamp(value) then
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
---@param visit fun(key: string, value: string)
---@param key string|nil
local function walk(value, visit, key)
  if type(value) == "string" then
    visit(key or "", value)
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
      walk(value[k], visit, type(k) == "string" and k or key)
    end
  end
end

---@alias Replacement { original: string, scrubbed: string }

---@param decoded any Decoded `sf --json` output
---@param alias string|nil The org alias the command was given
---@return Replacement[] replacements Longest original first
local function collect_replacements(decoded, alias)
  local by_original = {}
  local counts = {}
  local id_counts = {}

  local function add(original, scrubbed)
    if original ~= "" and original ~= scrubbed and not by_original[original] then
      by_original[original] = scrubbed
    end
  end

  -- sf may name the alias in a message without returning an alias field.
  if alias then
    counts.alias = 1
    add(alias, placeholder.alias(1))
  end

  local function add_id(value)
    if by_original[value] then
      return by_original[value]
    end
    local prefix = value:sub(1, 3)
    id_counts[prefix] = (id_counts[prefix] or 0) + 1
    local fake = string.format("%s%012dAAA", prefix, id_counts[prefix])
    add(value, fake:sub(1, #value))
    -- The 15-character form shows up inside tokens and other ids.
    add(value:sub(1, 15), fake:sub(1, 15))
    return by_original[value]
  end

  -- Ids first, so a token's org id prefix gets the org id's placeholder.
  walk(decoded, function(key, value)
    if kind_of(key, value) == "id" then
      add_id(value)
    end
  end)

  walk(decoded, function(key, value)
    if by_original[value] then
      return
    end
    if key == "apiVersion" then
      return add(value, API_VERSION)
    end
    local kind = kind_of(key, value)
    if not kind or kind == "id" then
      return
    end
    if kind == "token" then
      counts.token = (counts.token or 0) + 1
      -- An access token starts with the 15-character org id and a "!".
      local org_id = value:match("^(%w+)!")
      local prefix = org_id and is_sf_id(org_id) and add_id(org_id):sub(1, 15) or "00D000000000000"
      add(value, string.format("%s!FAKE_ACCESS_TOKEN_%d", prefix, counts.token))
    elseif kind == "timestamp" then
      add(value, "2026-01-01" .. value:sub(11):gsub("%d", "0"))
    else
      counts[kind] = (counts[kind] or 0) + 1
      add(value, placeholder[kind](counts[kind]))
      if kind == "url" or kind == "auth_url" then
        local host = host_of(value)
        if host then
          add(host, host_of(by_original[value]))
        end
      end
    end
  end)

  local replacements = {}
  for original, scrubbed in pairs(by_original) do
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

--- Applies the replacements to the string values of raw JSON text, leaving
--- keys, numbers and layout alone.
---@param json string
---@param replacements Replacement[]
---@return string
local function replace_in_json(json, replacements)
  local out = {}
  local pos = 1
  while true do
    local open = json:find('"', pos, true)
    if not open then
      break
    end
    local close = open + 1
    while true do
      local c = json:sub(close, close)
      if c == "" then
        error("unterminated JSON string", 0)
      elseif c == "\\" then
        close = close + 2
      elseif c == '"' then
        break
      else
        close = close + 1
      end
    end
    local content = json:sub(open + 1, close - 1)
    local is_key = json:find("^%s*:", close + 1) ~= nil
    table.insert(out, json:sub(pos, open))
    table.insert(out, is_key and content or replace_text(content, replacements))
    table.insert(out, '"')
    pos = close + 1
  end
  table.insert(out, json:sub(pos))
  return table.concat(out)
end

--- Replaces tokens, ids, usernames, URLs, timestamps and other org-specific
--- values in `sf --json` output with fixed placeholders, keeping the CLI's
--- formatting. Every occurrence is replaced, also inside other strings such
--- as warnings, and in `extra` (e.g. stderr).
---@param stdout string `sf --json` output
---@param extra string|nil Other output of the same call to scrub alike
---@param alias string|nil The org alias the command was given, scrubbed too
---@return string scrubbed_stdout
---@return string|nil scrubbed_extra
M.scrub = function(stdout, extra, alias)
  local ok, decoded = pcall(vim.json.decode, stdout)
  if not ok then
    error("not JSON: " .. tostring(decoded), 0)
  end
  local replacements = collect_replacements(decoded, alias)
  local scrubbed = replace_in_json(stdout, replacements)
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

-- ── Recording

---@param alias string
---@return string[]
local function org_display_argv(alias)
  return { "sf", "org", "display", "-o", alias, "--json" }
end

---@param text string
---@return string
local function long_string(text)
  local level = ""
  while text:find("]" .. level .. "]", 1, true) do
    level = level .. "="
  end
  return string.format("[%s[\n%s]%s]", level, text, level)
end

---@param fixture { shown: string, sf_version: string, date: string, code: integer, stdout: string, stderr: string|nil }
---@return string
M.render = function(fixture)
  local lines = {
    string.format("-- `%s`", fixture.shown),
    "--",
    string.format("-- RECORDED with %s on %s by scripts/record_fixture.lua, which", fixture.sf_version, fixture.date),
    "-- replaced tokens, ids, usernames, URLs and timestamps with placeholders.",
    "-- Re-record with `make record-fixture ORG=<alias>` instead of editing it.",
    "return {",
    "  recorded = true,",
    string.format("  code = %d,", fixture.code),
    string.format("  stdout = %s,", long_string(fixture.stdout)),
  }
  if fixture.stderr and fixture.stderr ~= "" then
    table.insert(lines, string.format("  stderr = %s,", long_string(fixture.stderr)))
  end
  table.insert(lines, "}")
  return table.concat(lines, "\n") .. "\n"
end

---@param argv string[]
---@return vim.SystemCompleted
local function run(argv)
  local ok, result = pcall(function()
    return vim.system(argv, { text = true }):wait()
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

---@return string e.g. "@salesforce/cli/2.60.0"
local function sf_version()
  local result = run({ "sf", "--version" })
  local version = (result.stdout or ""):match("^%s*(%S+)")
  if result.code ~= 0 or not version then
    error("`sf --version` failed: " .. failure_detail(result), 0)
  end
  return version
end

--- Runs `sf org display` against the org, scrubs its output and writes
--- `<dir>/org_display.lua`. On any failure it raises an error and leaves the
--- existing fixture as it was.
---@param opts { alias: string, dir: string|nil, date: string|nil }
---@return string path The fixture written
M.record = function(opts)
  assert(opts.alias and opts.alias ~= "", "an org alias is required")
  local path = (opts.dir or M.fixtures_dir) .. "/org_display.lua"

  local version = sf_version()
  local argv = org_display_argv(opts.alias)
  local cmd = table.concat(argv, " ")
  local result = run(argv)
  local decoded_ok, decoded = pcall(vim.json.decode, result.stdout or "")
  local status = decoded_ok and type(decoded) == "table" and decoded.status or 0
  if result.code ~= 0 then
    error(string.format("`%s` exited with %d: %s", cmd, result.code, failure_detail(result)), 0)
  elseif status ~= 0 then
    error(string.format("`%s` returned status %s: %s", cmd, status, failure_detail(result)), 0)
  end
  local ok, stdout, stderr = pcall(M.scrub, result.stdout or "", result.stderr, opts.alias)
  if not ok then
    error(string.format("`%s` output can't be recorded: %s", cmd, stdout), 0)
  end

  local content = M.render({
    shown = table.concat(org_display_argv(placeholder.alias(1)), " "),
    sf_version = version,
    date = opts.date or os.date("!%Y-%m-%d"),
    code = result.code,
    stdout = stdout,
    stderr = stderr,
  })

  -- Written aside and renamed, so a failed write leaves the old fixture whole.
  local tmp = path .. ".tmp"
  local file, open_err = io.open(tmp, "w")
  if not file then
    error("can't write " .. tmp .. ": " .. tostring(open_err), 0)
  end
  file:write(content)
  file:close()
  local renamed, rename_err = os.rename(tmp, path)
  if not renamed then
    os.remove(tmp)
    error("can't replace " .. path .. ": " .. tostring(rename_err), 0)
  end
  return path
end

return M
