-- `sf apex get test -i 7070000000FAKE1 -c --json`, which the plugin saves as
-- sf_cache/test_result.json to place coverage signs.
--
-- SYNTHETIC: not captured from a real org. Shaped after the JSON result of
-- salesforcecli/plugin-apex src/commands/apex/get/test.ts: a `TestResult` from
-- forcedotcom/salesforcedx-apex whose `coverage` holds per-class `coverage`
-- (with `lines`: line number -> 1 covered / 0 uncovered), `records` and
-- `summary`. Replace with a real, scrubbed capture and set `recorded = true`.
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
      "commandTime": "95 ms",
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
        "FullName": "SfProjectTest.constructsWithName",
        "perClassCoverage": [
          {
            "apexClassOrTriggerName": "SfProject",
            "apexClassOrTriggerId": "01p000000000001AAA",
            "apexTestClassId": "01p000000000002AAA",
            "apexTestMethodName": "constructsWithName",
            "numLinesCovered": 3,
            "numLinesUncovered": 1,
            "percentage": "75%"
          }
        ]
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
        "FullName": "SfProjectTest.constructsWithNull",
        "perClassCoverage": [
          {
            "apexClassOrTriggerName": "SfProject",
            "apexClassOrTriggerId": "01p000000000001AAA",
            "apexTestClassId": "01p000000000002AAA",
            "apexTestMethodName": "constructsWithNull",
            "numLinesCovered": 3,
            "numLinesUncovered": 1,
            "percentage": "75%"
          }
        ]
      }
    ],
    "coverage": {
      "coverage": [
        {
          "id": "01p000000000001AAA",
          "name": "SfProject",
          "totalLines": 4,
          "lines": { "1": 1, "4": 1, "5": 1, "6": 0 },
          "totalCovered": 3,
          "coveredPercent": 75
        }
      ],
      "records": [
        {
          "ApexTestClass": { "Id": "01p000000000002AAA", "Name": "SfProjectTest" },
          "Coverage": { "coveredLines": [1, 4, 5], "uncoveredLines": [6] },
          "TestMethodName": "constructsWithName",
          "NumLinesCovered": 3,
          "ApexClassOrTrigger": { "Id": "01p000000000001AAA", "Name": "SfProject" },
          "NumLinesUncovered": 1
        }
      ],
      "summary": {
        "totalLines": 4,
        "coveredLines": 3,
        "orgWideCoverage": "83%",
        "testRunCoverage": "75%"
      }
    }
  },
  "warnings": []
}
]==],
}
