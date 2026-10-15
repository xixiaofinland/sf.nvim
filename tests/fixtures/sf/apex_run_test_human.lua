-- `sf apex run test -n SfProjectTest -r human -w 5 -c`, the form the plugin
-- runs in its terminal; it reads the "Test Run Id" line to fetch coverage.
--
-- SYNTHETIC: not captured from a real org. Shaped after the HumanReporter in
-- forcedotcom/salesforcedx-apex src/reporters/humanReporter.ts, with the same
-- run as apex_run_test.lua. Replace with a real, scrubbed capture and set
-- `recorded = true`.
return {
  recorded = false,
  code = 0,
  stdout = [==[
=== Test Summary
NAME                 VALUE
───────────────────  ──────────────────────────────────
Outcome              Passed
Tests Ran            2
Pass Rate            100%
Fail Rate            0%
Skip Rate            0%
Test Run Id          7070000000FAKE1
Test Setup Time      0 ms
Test Execution Time  52 ms
Test Total Time      52 ms
Org Id               00D000000000001AAA
Username             admin@example.com
Org Wide Coverage    83%
Test Run Coverage    75%


=== Test Results
TEST NAME                         OUTCOME  MESSAGE  RUNTIME (MS)
────────────────────────────────  ───────  ───────  ────────────
SfProjectTest.constructsWithName  Pass              30
SfProjectTest.constructsWithNull  Pass              22
]==],
}
