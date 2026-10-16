-- Records every fixture of the sf fake from a throwaway scratch org, scrubbed:
--
--   make record-fixtures DEVHUB=<alias>
--   nvim -l scripts/record_fixtures.lua <Dev Hub alias> [fixtures dir]
--
-- It creates one scratch org from that Dev Hub, deploys a small project to
-- it, records and deletes the org again, also when a step fails. The
-- fixtures dir defaults to tests/fixtures/sf. See "Recording the fixtures" in
-- tests/helpers.lua.
local script_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local recorder = dofile(script_dir .. "/fixture_recorder.lua")

local devhub, dir = arg[1], arg[2]
if not devhub or devhub == "" then
  io.stderr:write("usage: nvim -l scripts/record_fixtures.lua <Dev Hub alias> [fixtures dir]\n")
  os.exit(2)
end

local ok, result = pcall(recorder.record, { devhub = devhub, dir = dir })
if not ok then
  io.stderr:write("record_fixtures: " .. tostring(result) .. "\n")
  os.exit(1)
end
for _, path in ipairs(result) do
  io.stdout:write("Recorded " .. path .. "\n")
end
