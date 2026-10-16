-- `sf apex run test -n SfProjectTest -w 5 -c --json -o my-scratch`
--
-- A second run of the same tests, reported as JSON; its test run id differs
-- from the human run's.
--
-- RECORDED with @salesforce/cli/2.153.5 on 2026-10-16 by scripts/record_fixtures.lua, which
-- replaced tokens, ids, usernames, URLs, timestamps and durations with placeholders.
-- Re-record with `make record-fixtures DEVHUB=<alias>` instead of editing it.
return {
  recorded = true,
  code = 0,
  stdout = [[
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
      "testRunId": "707000000000002",
      "testStartTime": "2026-01-01T00:00:00.000Z",
      "testsRan": 2,
      "userId": "005000000000001AAA",
      "username": "admin@example.com",
      "commandTime": "0 ms",
      "testExecutionTime": "0 ms",
      "testTotalTime": "0 ms",
      "orgWideCoverage": "66%",
      "testRunCoverage": "67%"
    },
    "tests": [
      {
        "Id": "07M000000000003AAA",
        "QueueItemId": "709000000000002AAA",
        "StackTrace": null,
        "Message": null,
        "AsyncApexJobId": "707000000000002AAA",
        "MethodName": "constructsWithName",
        "Outcome": "Pass",
        "ApexClass": {
          "Id": "01p000000000002AAA",
          "Name": "SfProjectTest",
          "NamespacePrefix": null
        },
        "RunTime": 0,
        "FullName": "SfProjectTest.constructsWithName"
      },
      {
        "Id": "07M000000000004AAA",
        "QueueItemId": "709000000000002AAA",
        "StackTrace": null,
        "Message": null,
        "AsyncApexJobId": "707000000000002AAA",
        "MethodName": "constructsWithNull",
        "Outcome": "Pass",
        "ApexClass": {
          "Id": "01p000000000002AAA",
          "Name": "SfProjectTest",
          "NamespacePrefix": null
        },
        "RunTime": 0,
        "FullName": "SfProjectTest.constructsWithNull"
      }
    ],
    "coverage": {
      "coverage": [
        {
          "id": "01p000000000001AAA",
          "name": "SfProject",
          "totalLines": 6,
          "lines": {
            "4": 1,
            "5": 1,
            "8": 1,
            "9": 1,
            "12": 0,
            "13": 0
          },
          "totalCovered": 4,
          "coveredPercent": 67
        }
      ],
      "records": [
        {
          "ApexTestClass": {
            "Id": "07M000000000003AAA",
            "Name": "SfProjectTest"
          },
          "Coverage": {
            "coveredLines": [
              4,
              5,
              8,
              9
            ],
            "uncoveredLines": [
              12,
              13
            ]
          },
          "TestMethodName": "constructsWithName",
          "NumLinesCovered": 4,
          "ApexClassOrTrigger": {
            "Id": "01p000000000001AAA",
            "Name": "SfProject"
          },
          "NumLinesUncovered": 2
        },
        {
          "ApexTestClass": {
            "Id": "07M000000000004AAA",
            "Name": "SfProjectTest"
          },
          "Coverage": {
            "coveredLines": [
              4,
              5,
              8,
              9
            ],
            "uncoveredLines": [
              12,
              13
            ]
          },
          "TestMethodName": "constructsWithNull",
          "NumLinesCovered": 4,
          "ApexClassOrTrigger": {
            "Id": "01p000000000001AAA",
            "Name": "SfProject"
          },
          "NumLinesUncovered": 2
        }
      ],
      "summary": {
        "totalLines": 6,
        "coveredLines": 4,
        "orgWideCoverage": "66%",
        "testRunCoverage": "67%"
      }
    }
  },
  "warnings": []
}
]],
}
