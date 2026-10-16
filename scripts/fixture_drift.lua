-- Compares freshly recorded fixtures with the committed ones and acts on the
-- difference, for the weekly drift check (.github/workflows/fixture-drift.yml).
-- Run it through scripts/check_fixture_drift.lua; tests load it with `dofile`
-- and drive it against a fake `gh` on PATH.

local M = {}

-- ── Shapes

local EMPTY_DICT_MT = getmetatable(vim.empty_dict())

---@param value any Decoded JSON
---@return string
local function type_of(value)
  if value == vim.NIL then
    return "null"
  elseif type(value) == "table" then
    -- vim.json.decode gives `{}` the empty dict's metatable and `[]` none.
    if getmetatable(value) ~= EMPTY_DICT_MT and vim.islist(value) then
      return "array"
    end
    return "object"
  end
  return type(value)
end

---@param shape table<string, table<string, true>>
---@param path string
---@param value any
local function collect_shape(shape, path, value)
  local t = type_of(value)
  shape[path] = shape[path] or {}
  shape[path][t] = true
  if t == "array" then
    -- Every item shares one path, so the shape is the union of the items'.
    for _, item in ipairs(value) do
      collect_shape(shape, path .. "[]", item)
    end
  elseif t == "object" then
    for k, v in pairs(value) do
      collect_shape(shape, path == "" and k or (path .. "." .. k), v)
    end
  end
end

-- Key paths, such as `result.records[].Id`, to the types found there; the
-- top level is "".
---@param json string
---@return table<string, string>
local function shape_of(json)
  local raw = {}
  collect_shape(raw, "", vim.json.decode(json, { luanil = { object = false, array = false } }))
  local shape = {}
  for path, types in pairs(raw) do
    local names = vim.tbl_keys(types)
    table.sort(names)
    shape[path] = table.concat(names, "|")
  end
  return shape
end

---@param path string
---@return string
local function shown_path(path)
  return path == "" and "." or path
end

---@alias ShapeChanges { added: string[], removed: string[], retyped: string[] }

--- The key paths added, removed or retyped between two JSON documents; values
--- that changed without changing type aren't reported.
---@param old_json string
---@param new_json string
---@return ShapeChanges
M.shape_changes = function(old_json, new_json)
  local old, new = shape_of(old_json), shape_of(new_json)
  local changes = { added = {}, removed = {}, retyped = {} }
  local paths = vim.tbl_keys(vim.tbl_extend("force", {}, old, new))
  table.sort(paths)
  for _, path in ipairs(paths) do
    local from, to = old[path], new[path]
    if not from then
      table.insert(changes.added, string.format("%s (%s)", shown_path(path), to))
    elseif not to then
      table.insert(changes.removed, string.format("%s (%s)", shown_path(path), from))
    elseif from ~= to then
      table.insert(changes.retyped, string.format("%s: %s → %s", shown_path(path), from, to))
    end
  end
  return changes
end

-- ── Fixtures

-- The header line that changes on every recording.
---@param text string
---@return string
local function without_recorded_line(text)
  return (text:gsub("\n%-%- RECORDED with [^\n]*", ""))
end

---@param text string
---@return string|nil e.g. "2.160.0"
local function sf_version_of(text)
  return text:match("RECORDED with @salesforce/cli/(%S+) on") or text:match("RECORDED with (%S+) on")
end

---@param text string
---@return table|nil
local function load_fixture(text)
  local chunk = load(text, "fixture", "t", {})
  if not chunk then
    return nil
  end
  local ok, fixture = pcall(chunk)
  return ok and type(fixture) == "table" and fixture or nil
end

---@param text string|nil
---@return boolean
local function is_json(text)
  return text ~= nil and (pcall(vim.json.decode, text))
end

---@alias FixtureChange { name: string, lines: string[] }

--- What changed in one fixture, one line each, or nil when nothing but its
--- RECORDED line did.
---@param name string
---@param old_text string|nil Nil for a fixture that is new
---@param new_text string
---@return FixtureChange|nil
local function fixture_change(name, old_text, new_text)
  if old_text and without_recorded_line(old_text) == without_recorded_line(new_text) then
    return nil
  end
  if not old_text then
    return { name = name, lines = { "New fixture." } }
  end
  local old, new = load_fixture(old_text), load_fixture(new_text)
  if not old or not new then
    return { name = name, lines = { "The fixture file changed, and one side doesn't load." } }
  end

  local lines = {}
  if old.code ~= new.code then
    table.insert(lines, string.format("Exit code: %s → %s", old.code, new.code))
  end
  if old.stdout ~= new.stdout then
    if is_json(old.stdout) and is_json(new.stdout) then
      local shape = M.shape_changes(old.stdout, new.stdout)
      for _, kind in ipairs({ { "Added", shape.added }, { "Removed", shape.removed }, { "Retyped", shape.retyped } }) do
        for _, entry in ipairs(kind[2]) do
          -- Paths hold neither spaces nor colons; the type follows either.
          table.insert(lines, kind[1] .. ": " .. entry:gsub("^([^%s:]+)", "`%1`"))
        end
      end
      if #shape.added + #shape.removed + #shape.retyped == 0 then
        table.insert(lines, "Values in stdout changed; its shape didn't.")
      end
    else
      table.insert(lines, "stdout changed (not JSON).")
    end
  end
  if (old.stderr or "") ~= (new.stderr or "") then
    table.insert(lines, "stderr changed.")
  end
  if #lines == 0 then
    table.insert(lines, "Only the header changed.")
  end
  return { name = name, lines = lines }
end

-- ── Leak guard

-- Lines of a multi-line secret (a PEM key's body) count on their own: a
-- fixture holding one of them leaks part of the key.
local MIN_LINE = 16

---@param value string
---@return string[]
local function needles(value)
  value = vim.trim(value)
  if value == "" or value == "/" then
    return {}
  end
  local list = { value }
  if value:find("\n") then
    for line in value:gmatch("[^\r\n]+") do
      line = vim.trim(line)
      if #line >= MIN_LINE and not line:match("^%-%-%-%-%-") then
        table.insert(list, line)
      end
    end
  end
  return list
end

--- Raises an error naming each fixture that holds a secret's value or the
--- home directory, by the secret's name: the value itself stays out of logs.
---@param files { name: string, text: string }[]
---@param secrets table<string, string>
---@param home string|nil
local function guard_leaks(files, secrets, home)
  local named = {}
  for name, value in pairs(secrets) do
    table.insert(named, { name = name, needles = needles(value) })
  end
  table.sort(named, function(a, b)
    return a.name < b.name
  end)
  if home then
    table.insert(named, { name = "the home directory", needles = needles(home) })
  end

  local leaks = {}
  for _, file in ipairs(files) do
    for _, secret in ipairs(named) do
      for _, needle in ipairs(secret.needles) do
        if file.text:find(needle, 1, true) then
          table.insert(leaks, string.format("%s holds the value of %s", file.name, secret.name))
          break
        end
      end
    end
  end
  if #leaks > 0 then
    error("leak guard: " .. table.concat(leaks, "; ") .. ". Nothing was pushed.", 0)
  end
end

-- ── Test output

--- The ids of the cases mini.test reports as failed, once each, in order.
---@param output string
---@return string[]
local function failing_tests(output)
  local seen, list = {}, {}
  for line in output:gsub("\27%[[%d;]*m", ""):gmatch("[^\n]+") do
    local id = line:match("^FAIL in (.-): ")
    if id and not seen[id] then
      seen[id] = true
      table.insert(list, id)
    end
  end
  return list
end

-- ── Texts

M.BRANCH = "fixture-drift"

-- Marks the drift issue, so a later run finds it whatever its title became.
M.MARKER = "<!-- sf.nvim fixture drift -->"

---@param changes FixtureChange[]
---@return string
local function changes_text(changes)
  local lines = {}
  for _, change in ipairs(changes) do
    table.insert(lines, string.format("### `%s`", change.name))
    table.insert(lines, "")
    for _, line in ipairs(change.lines) do
      table.insert(lines, "- " .. line)
    end
    table.insert(lines, "")
  end
  return table.concat(lines, "\n")
end

---@param failures string[]
---@param run_url string|nil
---@return string
local function failures_text(failures, run_url)
  local lines = {}
  for _, id in ipairs(failures) do
    table.insert(lines, string.format("- `%s`", id))
  end
  if #lines == 0 then
    table.insert(lines, "`make test` failed without naming a test; its output is in the run's log.")
  end
  if run_url then
    table.insert(lines, "")
    table.insert(lines, "Run: " .. run_url)
  end
  return table.concat(lines, "\n")
end

---@class DriftReport
---@field version string
---@field changes FixtureChange[]
---@field passed boolean
---@field failures string[]
---@field run_url string|nil
---@field pr integer|nil

---@param r DriftReport
---@return string
local function pr_body(r)
  local verdict = r.passed and "`make test` passes on them, so this merges itself."
    or "`make test` fails on them: the plugin has to follow the CLI first. The drift issue says what failed; leave this PR open."
  return table.concat({
    string.format("The weekly drift check re-recorded the fixtures with sf %s. %s", r.version, verdict),
    "",
    "## What changed",
    "",
    changes_text(r.changes),
    "Values the recorder scrubs (ids, tokens, timestamps) don't count; each header's `RECORDED with` line changed in every fixture.",
  }, "\n")
end

---@param r DriftReport
---@return string
local function issue_body(r)
  return table.concat({
    M.MARKER,
    "## What to build",
    "",
    string.format(
      "The weekly drift check re-recorded the fixtures with sf %s, and `make test` fails on them: the plugin has to follow the CLI's new output. The new fixtures are in #%d, on branch `%s`.",
      r.version,
      r.pr,
      M.BRANCH
    ),
    "",
    string.format(
      "Bring them into your branch with `git fetch origin %s && git checkout origin/%s -- tests/fixtures/sf`, then change the plugin (not the fixtures) until `make test` passes. Once that is on `dev`, the next drift check finds nothing new and closes #%d and this issue.",
      M.BRANCH,
      M.BRANCH,
      r.pr
    ),
    "",
    "## Failing tests",
    "",
    failures_text(r.failures, r.run_url),
    "",
    "## Output changes",
    "",
    changes_text(r.changes),
    "## Acceptance criteria",
    "",
    string.format("- [ ] `make test` passes with the fixtures of #%d.", r.pr),
    "",
  }, "\n")
end

---@param r DriftReport
---@return string
local function comment_body(r)
  return table.concat({
    string.format(
      "The drift check ran again with sf %s, and `make test` still fails. #%d now holds these fixtures.",
      r.version,
      r.pr
    ),
    "",
    "## Failing tests",
    "",
    failures_text(r.failures, r.run_url),
    "",
    "## Output changes",
    "",
    changes_text(r.changes),
  }, "\n")
end

-- ── Running it

---@param argv string[]
---@param cwd string
---@return string stdout
local function system(argv, cwd)
  local ok, result = pcall(function()
    return vim.system(argv, { cwd = cwd, text = true }):wait()
  end)
  if not ok then
    error(string.format("could not run `%s`: %s", argv[1], result), 0)
  end
  if result.code ~= 0 then
    -- Bodies stay out of the message: only the command's first words.
    local shown = table.concat(vim.list_slice(argv, 1, 3), " ")
    error(string.format("`%s` exited with %d: %s", shown, result.code, vim.trim(result.stderr or "")), 0)
  end
  return result.stdout or ""
end

---@param text string
---@return string path
local function body_file(text)
  local path = vim.fn.tempname() .. ".md"
  vim.fn.writefile(vim.split(text, "\n", { plain = true }), path, "b")
  return path
end

---@param url string
---@return integer|nil
local function number_of(url)
  return tonumber(url:match("/(%d+)%s*$"))
end

---@class DriftOptions
---@field root string The repository
---@field fixtures string The fixtures dir, relative to root
---@field base string The branch the PR targets
---@field secrets table<string, string> Name to value, for the leak guard
---@field home string|nil The home directory, for the leak guard
---@field test_cmd string[] e.g. { "make", "test" }
---@field run_url string|nil The workflow run, linked from the issue
---@field log fun(msg: string)|nil

--- Compares the fixtures in the working tree, just recorded, with those
--- committed at HEAD and acts on it:
---   - nothing but the RECORDED lines changed: nothing to do, beyond closing a
---     drift PR and issue still open from an earlier run;
---   - changed, and the tests pass: commits them to M.BRANCH, opens a PR
---     against `base` and squash-merges it, and closes an open drift issue;
---   - changed, and the tests fail: opens the same PR, or updates the one left
---     open, without merging it, and opens a ready-for-agent issue, or
---     comments on the one still open.
--- Before any of it, the leak guard raises an error if a fixture holds a
--- secret's value or the home directory.
---@param opts DriftOptions
---@return { outcome: "unchanged"|"merged"|"needs_fix", pr: integer|nil, issue: integer|nil }
M.run = function(opts)
  local log = opts.log or function(msg)
    io.stdout:write(msg .. "\n")
  end
  local function gh(argv)
    return system(vim.list_extend({ "gh" }, argv), opts.root)
  end
  local function git(argv)
    return system(vim.list_extend({ "git" }, argv), opts.root)
  end

  local dir = opts.root .. "/" .. opts.fixtures
  local files = {}
  for _, file in ipairs(vim.fn.readdir(dir)) do
    if file:match("%.lua$") then
      local text = table.concat(vim.fn.readfile(dir .. "/" .. file, "b"), "\n")
      table.insert(files, { name = file:gsub("%.lua$", ""), text = text })
    end
  end
  guard_leaks(files, opts.secrets, opts.home)

  local changes, version = {}, nil
  for _, file in ipairs(files) do
    -- Not `git()`: a fixture new in the working tree isn't at HEAD.
    local shown = vim
      .system({ "git", "show", "HEAD:" .. opts.fixtures .. "/" .. file.name .. ".lua" }, {
        cwd = opts.root,
        text = true,
      })
      :wait()
    local old = shown.code == 0 and shown.stdout or nil
    local change = fixture_change(file.name, old, file.text)
    if change then
      table.insert(changes, change)
    end
    version = version or sf_version_of(file.text)
  end
  version = version or "unknown"

  local function open_pr()
    local list = vim.json.decode(gh({ "pr", "list", "--head", M.BRANCH, "--state", "open", "--json", "number,url" }))
    return list[1] and list[1].number
  end
  local function open_issue()
    local list = vim.json.decode(gh({ "issue", "list", "--state", "open", "--limit", "200", "--json", "number,body" }))
    for _, i in ipairs(list) do
      if (i.body or ""):find(M.MARKER, 1, true) then
        return i.number
      end
    end
  end

  if #changes == 0 then
    log("The fixtures match sf " .. version .. "'s output; nothing to do.")
    -- Left from a drift whose fix, fixtures included, has reached dev since.
    local stale_pr, stale_issue = open_pr(), open_issue()
    local done = "`" .. opts.base .. "`'s fixtures match sf " .. version .. "'s output now."
    if stale_pr then
      gh({ "pr", "close", tostring(stale_pr), "--delete-branch", "--comment", done })
      log("Closed the drift PR #" .. stale_pr .. ", which held nothing new any more.")
    end
    if stale_issue then
      gh({ "issue", "close", tostring(stale_issue), "--comment", done })
      log("Closed the drift issue #" .. stale_issue .. ".")
    end
    return { outcome = "unchanged" }
  end

  log("The output of sf " .. version .. " changed:\n" .. changes_text(changes))
  local tested = vim.system(opts.test_cmd, { cwd = opts.root, text = true }):wait()
  local output = (tested.stdout or "") .. (tested.stderr or "")
  log(output)
  local report = {
    version = version,
    changes = changes,
    passed = tested.code == 0,
    failures = tested.code == 0 and {} or failing_tests(output),
    run_url = opts.run_url,
  }

  local title = "test: re-record fixtures for sf " .. version
  git({ "checkout", "-B", M.BRANCH })
  git({ "add", "-A", "--", opts.fixtures })
  git({
    "-c",
    "user.name=github-actions[bot]",
    "-c",
    "user.email=41898282+github-actions[bot]@users.noreply.github.com",
    "-c",
    "commit.gpgsign=false",
    "commit",
    "-m",
    title,
  })
  git({ "push", "--force", "origin", "HEAD:refs/heads/" .. M.BRANCH })

  local pr = open_pr()
  local body = body_file(pr_body(report))
  if pr then
    gh({ "pr", "edit", tostring(pr), "--title", title, "--body-file", body })
  else
    local url = gh({ "pr", "create", "--base", opts.base, "--head", M.BRANCH, "--title", title, "--body-file", body })
    pr = number_of(url)
    if not pr then
      error("`gh pr create` printed no PR URL: " .. url, 0)
    end
  end
  log("PR #" .. pr .. ": " .. title)
  report.pr = pr

  local issue = open_issue()
  if report.passed then
    gh({ "pr", "merge", tostring(pr), "--squash", "--delete-branch" })
    log("Merged #" .. pr .. ".")
    if issue then
      gh({
        "issue",
        "close",
        tostring(issue),
        "--comment",
        string.format("The tests pass with sf %s's output; merged #%d.", version, pr),
      })
      log("Closed the drift issue #" .. issue .. ".")
    end
    return { outcome = "merged", pr = pr }
  end

  if issue then
    gh({ "issue", "comment", tostring(issue), "--body-file", body_file(comment_body(report)) })
    log("Commented on the drift issue #" .. issue .. ".")
  else
    local url = gh({
      "issue",
      "create",
      "--title",
      "fix: follow the --json output of sf " .. version,
      "--label",
      "ready-for-agent",
      "--body-file",
      body_file(issue_body(report)),
    })
    issue = number_of(url)
    log("Opened the drift issue " .. vim.trim(url) .. ".")
  end
  return { outcome = "needs_fix", pr = pr, issue = issue }
end

return M
