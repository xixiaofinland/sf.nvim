-- Records the org display fixture from a real org, scrubbed:
--
--   make record-fixture ORG=<alias>
--   nvim -l scripts/record_fixture.lua <alias> [fixtures dir]
--
-- Use a throwaway org: the recorder runs `sf org display` against it. The
-- fixtures dir defaults to tests/fixtures/sf.
local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local recorder = dofile(script_dir .. "/fixture_recorder.lua")

local alias, dir = arg[1], arg[2]
if not alias or alias == "" then
  io.stderr:write("usage: nvim -l scripts/record_fixture.lua <org alias> [fixtures dir]\n")
  os.exit(2)
end

local ok, result = pcall(recorder.record, { alias = alias, dir = dir })
if not ok then
  io.stderr:write("record_fixture: " .. tostring(result) .. "\nThe existing fixture was left untouched.\n")
  os.exit(1)
end
io.stdout:write("Recorded " .. result .. "\n")
