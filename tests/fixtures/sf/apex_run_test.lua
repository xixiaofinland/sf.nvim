-- `sf apex run test -n SfProjectTest -w 5 -c --json`
--
-- SYNTHETIC: not captured from a real org. Shaped after the JSON result of
-- salesforcecli/plugin-apex src/commands/apex/run/test.ts, which reports a
-- `TestResult` from forcedotcom/salesforcedx-apex (`summary`, `tests`,
-- `coverage`). Coverage is left out here; see apex_get_test_coverage.lua.
-- Replace with a real, scrubbed capture and set `recorded = true`.
--
-- The plugin itself runs tests with `-r human`; see apex_run_test_human.lua.
return {
  recorded = false,
  code = 0,
  stdout = [==[
{
  "status": 0,
  "result": {
    "summary": {
      "failRate": "0%",
      "failing": 0,
      "hostname": "https://fake-company.my.salesforce.com",
      "orgId": "00D000000000001AAA",
      "outcome": "Passed",
      "passRate": "100%",
      "passing": 2,
      "skipped": 0,
      "testRunId": "7070000000FAKE1",
      "testStartTime": "2026-01-01T09:00:00.000Z",
      "testsRan": 2,
      "userId": "005000000000001AAA",
      "username": "admin@example.com",
      "commandTime": "120 ms",
      "testExecutionTime": "52 ms",
      "testTotalTime": "52 ms",
      "orgWideCoverage": "83%",
      "testRunCoverage": "75%"
    },
    "tests": [
      {
        "Id": "07M000000000001AAA",
        "QueueItemId": "709000000000001AAA",
        "StackTrace": null,
        "Message": null,
        "AsyncApexJobId": "7070000000FAKE1",
        "MethodName": "constructsWithName",
        "Outcome": "Pass",
        "ApexClass": { "Id": "01p000000000002AAA", "Name": "SfProjectTest", "NamespacePrefix": null },
        "RunTime": 30,
        "FullName": "SfProjectTest.constructsWithName"
      },
      {
        "Id": "07M000000000002AAA",
        "QueueItemId": "709000000000001AAA",
        "StackTrace": null,
        "Message": null,
        "AsyncApexJobId": "7070000000FAKE1",
        "MethodName": "constructsWithNull",
        "Outcome": "Pass",
        "ApexClass": { "Id": "01p000000000002AAA", "Name": "SfProjectTest", "NamespacePrefix": null },
        "RunTime": 22,
        "FullName": "SfProjectTest.constructsWithNull"
      }
    ]
  },
  "warnings": []
}
]==],
}
