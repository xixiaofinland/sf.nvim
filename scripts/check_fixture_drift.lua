-- Acts on the fixtures `make record-fixtures` just re-recorded, for the weekly
-- drift check (.github/workflows/fixture-drift.yml):
--
--   nvim -l scripts/check_fixture_drift.lua
--
-- It reads the Dev Hub secrets from the environment for its leak guard and
-- needs `gh` logged in (GH_TOKEN). The outcomes are described at `run` in
-- scripts/fixture_drift.lua.
local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local drift = dofile(script_dir .. "/fixture_drift.lua")

local secrets = {}
for _, name in ipairs({ "SF_DEVHUB_CLIENT_ID", "SF_DEVHUB_USERNAME", "SF_DEVHUB_JWT_KEY" }) do
  secrets[name] = vim.env[name] or ""
  -- The leak guard is all that needs them; `make test`, git and gh don't.
  vim.env[name] = nil
end

local run_url
if vim.env.GITHUB_RUN_ID then
  run_url =
    string.format("%s/%s/actions/runs/%s", vim.env.GITHUB_SERVER_URL, vim.env.GITHUB_REPOSITORY, vim.env.GITHUB_RUN_ID)
end

local ok, result = pcall(drift.run, {
  root = vim.fn.fnamemodify(script_dir, ":h"),
  fixtures = "tests/fixtures/sf",
  base = "dev",
  secrets = secrets,
  home = vim.uv.os_homedir(),
  test_cmd = { "make", "test" },
  run_url = run_url,
})
if not ok then
  io.stderr:write("check_fixture_drift: " .. tostring(result) .. "\n")
  os.exit(1)
end
