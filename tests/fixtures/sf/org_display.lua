-- `sf org display -o my-scratch --json`
--
-- Its access token and API version feed the sObject refresh.
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
    "id": "00D000000000001AAA",
    "devHubId": "user2@example.com",
    "apiVersion": "62.0",
    "accessToken": "00D000000000000!FAKE_ACCESS_TOKEN_1",
    "instanceUrl": "https://fake-company.my.salesforce.com",
    "username": "admin@example.com",
    "clientId": "PlatformCLI",
    "status": "Active",
    "expirationDate": "2026-01-01",
    "createdBy": "user2@example.com",
    "edition": "Developer",
    "orgName": "Fake Company",
    "createdDate": "2026-01-01T00:00:00.000+0000",
    "signupUsername": "admin@example.com",
    "alias": "my-scratch"
  },
  "warnings": []
}
]],
}
