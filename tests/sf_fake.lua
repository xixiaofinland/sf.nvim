-- Fake for the process boundary, loaded into the child Neovim by
-- `child.sf_fake.install()` in tests/helpers.lua (see the usage notes there).
--
-- Replaces `vim.system`, `vim.fn.jobstart` and `vim.fn.termopen` so no test can
-- reach a real `sf`: each call is matched against the installed rules, answered
-- with the rule's canned stdout/stderr/exit code, and recorded. A command no
-- rule matches raises an error naming it.

local Fake = {}

local original = {
  system = vim.system,
  jobstart = vim.fn.jobstart,
  termopen = vim.fn.termopen,
  executable = vim.fn.executable,
}

---@class SfFakeRule
---@field cmd string Plain substring the command line must contain
---@field stdout string|nil
---@field stderr string|nil
---@field code integer|nil Exit code, 0 by default

---@type SfFakeRule[]
Fake.rules = {}
-- Every command received, in order: { cmd = string, argv = table|nil, via = string, stdin = string|nil }
Fake.calls = {}
-- Commands no rule matched; `wait()` reports them even when the error was
-- raised in a scheduled callback, where it would not reach the test.
Fake.unmatched = {}
-- "schedule": callbacks run on a later event-loop tick, as real processes do.
-- "sync": callbacks run before the faked function returns.
Fake.mode = "schedule"
Fake.pending = 0

local next_job_id = 1000

---@param cmd string|string[]
---@return string
local function to_cmd_line(cmd)
  if type(cmd) == "table" then
    return table.concat(cmd, " ")
  end
  return cmd
end

---@param cmd_line string
---@return SfFakeRule
local function match(cmd_line)
  for _, rule in ipairs(Fake.rules) do
    if cmd_line:find(rule.cmd, 1, true) then
      return rule
    end
  end
  table.insert(Fake.unmatched, cmd_line)
  error("sf fake: no rule matches command: " .. cmd_line, 0)
end

---@param cmd string|string[]
---@param via string
---@param stdin string|nil
---@return SfFakeRule
local function record_and_match(cmd, via, stdin)
  local cmd_line = to_cmd_line(cmd)
  table.insert(Fake.calls, {
    cmd = cmd_line,
    argv = type(cmd) == "table" and vim.deepcopy(cmd) or nil,
    via = via,
    stdin = stdin,
  })
  return match(cmd_line)
end

local function deliver(fn)
  if Fake.mode == "sync" then
    return fn()
  end
  Fake.pending = Fake.pending + 1
  vim.schedule(function()
    Fake.pending = Fake.pending - 1
    fn()
  end)
end

-- Job callbacks get output as lines, the way `stdout_buffered` delivers it.
---@param s string|nil
---@return string[]
local function to_lines(s)
  return vim.split(s or "", "\n", { plain = true })
end

local function fake_system(cmd, opts, on_exit)
  if type(opts) == "function" then
    on_exit, opts = opts, nil
  end
  opts = opts or {}

  local stdin = type(opts.stdin) == "string" and opts.stdin or nil
  local rule = record_and_match(cmd, "system", stdin)
  local result = { code = rule.code or 0, signal = 0, stdout = rule.stdout or "", stderr = rule.stderr or "" }

  if on_exit then
    deliver(function()
      on_exit(result)
    end)
  end

  return {
    pid = next_job_id,
    wait = function()
      return result
    end,
    kill = function() end,
    write = function() end,
    is_closing = function()
      return true
    end,
  }
end

local function run_job(cmd, opts, via)
  opts = opts or {}
  local rule = record_and_match(cmd, via)
  next_job_id = next_job_id + 1
  local job_id = next_job_id
  -- A terminal job writes to the buffer that was current when it started.
  local term_buf = vim.api.nvim_get_current_buf()

  deliver(function()
    if via == "termopen" and vim.api.nvim_buf_is_valid(term_buf) then
      vim.api.nvim_buf_set_lines(term_buf, 0, -1, false, to_lines(rule.stdout))
    end
    if opts.on_stdout then
      opts.on_stdout(job_id, to_lines(rule.stdout), "stdout")
    end
    if opts.on_stderr then
      opts.on_stderr(job_id, to_lines(rule.stderr), "stderr")
    end
    if opts.on_exit then
      opts.on_exit(job_id, rule.code or 0, "exit")
    end
  end)

  return job_id
end

local function fake_jobstart(cmd, opts)
  -- Since Neovim 0.11 `jobstart(cmd, { term = true })` replaces `termopen()`.
  return run_job(cmd, opts, opts and opts.term and "termopen" or "jobstart")
end

local function fake_termopen(cmd, opts)
  return run_job(cmd, opts, "termopen")
end

-- The plugin checks `executable("sf")` before running it; the fake stands in
-- for every program its rules name.
local function fake_executable(name)
  for _, rule in ipairs(Fake.rules) do
    if vim.split(rule.cmd, " ", { plain = true })[1] == name then
      return 1
    end
  end
  return original.executable(name)
end

---@param rules SfFakeRule[]
---@param opts { mode: "schedule"|"sync"|nil }|nil
function Fake.install(rules, opts)
  Fake.rules = rules or {}
  Fake.calls = {}
  Fake.unmatched = {}
  Fake.pending = 0
  Fake.mode = (opts and opts.mode) or "schedule"

  vim.system = fake_system
  vim.fn.jobstart = fake_jobstart
  vim.fn.termopen = fake_termopen
  vim.fn.executable = fake_executable
end

-- Waits until every faked process has delivered its callbacks, including the
-- callbacks those deferred again with `vim.schedule`/`vim.schedule_wrap`.
---@param timeout integer|nil Milliseconds
function Fake.wait(timeout)
  timeout = timeout or 1000
  local deadline = vim.uv.now() + timeout
  repeat
    if not vim.wait(math.max(deadline - vim.uv.now(), 0), function()
      return Fake.pending == 0
    end) then
      error(string.format("sf fake: %d callback(s) still pending after %dms", Fake.pending, timeout), 0)
    end
    -- A marker scheduled now runs after anything already queued, so the
    -- plugin's own scheduled continuations have run once it has.
    local flushed = false
    vim.schedule(function()
      flushed = true
    end)
    vim.wait(math.max(deadline - vim.uv.now(), 0), function()
      return flushed
    end)
  until Fake.pending == 0

  if #Fake.unmatched > 0 then
    error("sf fake: no rule matches command: " .. Fake.unmatched[1], 0)
  end
end

return Fake
