-- `sf org list --json --skip-connection-status`
--
-- SYNTHETIC: not captured from a real org. Shaped after `OrgListResult` in
-- salesforcecli/plugin-org src/commands/org/list.ts (`nonScratchOrgs` is the
-- union of `devHubs`, `sandboxes` and `other`). Replace with a real, scrubbed
-- capture and set `recorded = true`.
--
-- Orgs: "devhub" (Dev Hub, the default target org), "uat" (sandbox), an org
-- with no alias, and the scratch org "my-scratch".
return {
  recorded = false,
  code = 0,
  stdout = [==[
{
  "status": 0,
  "result": {
    "other": [
      {
        "accessToken": "00D000000000003AAA!FAKE_ACCESS_TOKEN_OTHER",
        "instanceUrl": "https://fake-other.my.salesforce.com",
        "orgId": "00D000000000003AAA",
        "username": "admin@other.example.com",
        "loginUrl": "https://login.salesforce.com",
        "clientId": "PlatformCLI",
        "isDevHub": false,
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 9:00:00 AM",
        "isSandbox": false,
        "isScratch": false,
        "tracksSource": false,
        "isDefaultUsername": false,
        "isDefaultDevHubUsername": false,
        "connectedStatus": "Unknown",
        "lastUsed": "2026-01-01T09:00:00.000Z"
      }
    ],
    "sandboxes": [
      {
        "accessToken": "00D000000000002AAA!FAKE_ACCESS_TOKEN_UAT",
        "instanceUrl": "https://fake-company--uat.sandbox.my.salesforce.com",
        "orgId": "00D000000000002AAA",
        "username": "admin@example.com.uat",
        "loginUrl": "https://test.salesforce.com",
        "clientId": "PlatformCLI",
        "isDevHub": false,
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 9:00:00 AM",
        "isSandbox": true,
        "isScratch": false,
        "tracksSource": true,
        "alias": "uat",
        "isDefaultUsername": false,
        "isDefaultDevHubUsername": false,
        "connectedStatus": "Unknown",
        "lastUsed": "2026-01-01T09:00:00.000Z"
      }
    ],
    "nonScratchOrgs": [
      {
        "accessToken": "00D000000000001AAA!FAKE_ACCESS_TOKEN_DEVHUB",
        "instanceUrl": "https://fake-company.my.salesforce.com",
        "orgId": "00D000000000001AAA",
        "username": "admin@example.com",
        "loginUrl": "https://login.salesforce.com",
        "clientId": "PlatformCLI",
        "isDevHub": true,
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 9:00:00 AM",
        "isSandbox": false,
        "isScratch": false,
        "tracksSource": false,
        "alias": "devhub",
        "isDefaultUsername": true,
        "isDefaultDevHubUsername": true,
        "defaultMarker": "(D),(U)",
        "connectedStatus": "Unknown",
        "lastUsed": "2026-01-01T09:00:00.000Z"
      },
      {
        "accessToken": "00D000000000002AAA!FAKE_ACCESS_TOKEN_UAT",
        "instanceUrl": "https://fake-company--uat.sandbox.my.salesforce.com",
        "orgId": "00D000000000002AAA",
        "username": "admin@example.com.uat",
        "loginUrl": "https://test.salesforce.com",
        "clientId": "PlatformCLI",
        "isDevHub": false,
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 9:00:00 AM",
        "isSandbox": true,
        "isScratch": false,
        "tracksSource": true,
        "alias": "uat",
        "isDefaultUsername": false,
        "isDefaultDevHubUsername": false,
        "connectedStatus": "Unknown",
        "lastUsed": "2026-01-01T09:00:00.000Z"
      },
      {
        "accessToken": "00D000000000003AAA!FAKE_ACCESS_TOKEN_OTHER",
        "instanceUrl": "https://fake-other.my.salesforce.com",
        "orgId": "00D000000000003AAA",
        "username": "admin@other.example.com",
        "loginUrl": "https://login.salesforce.com",
        "clientId": "PlatformCLI",
        "isDevHub": false,
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 9:00:00 AM",
        "isSandbox": false,
        "isScratch": false,
        "tracksSource": false,
        "isDefaultUsername": false,
        "isDefaultDevHubUsername": false,
        "connectedStatus": "Unknown",
        "lastUsed": "2026-01-01T09:00:00.000Z"
      }
    ],
    "devHubs": [
      {
        "accessToken": "00D000000000001AAA!FAKE_ACCESS_TOKEN_DEVHUB",
        "instanceUrl": "https://fake-company.my.salesforce.com",
        "orgId": "00D000000000001AAA",
        "username": "admin@example.com",
        "loginUrl": "https://login.salesforce.com",
        "clientId": "PlatformCLI",
        "isDevHub": true,
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 9:00:00 AM",
        "isSandbox": false,
        "isScratch": false,
        "tracksSource": false,
        "alias": "devhub",
        "isDefaultUsername": true,
        "isDefaultDevHubUsername": true,
        "defaultMarker": "(D),(U)",
        "connectedStatus": "Unknown",
        "lastUsed": "2026-01-01T09:00:00.000Z"
      }
    ],
    "scratchOrgs": [
      {
        "accessToken": "00D000000000004AAA!FAKE_ACCESS_TOKEN_SCRATCH",
        "instanceUrl": "https://fake-scratch-1234.scratch.my.salesforce.com",
        "orgId": "00D000000000004AAA",
        "username": "test-fake1234@example.com",
        "loginUrl": "https://CS1.salesforce.com",
        "clientId": "PlatformCLI",
        "createdOrgInstance": "CS1",
        "devHubUsername": "admin@example.com",
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 9:00:00 AM",
        "isDevHub": false,
        "isSandbox": false,
        "isScratch": true,
        "tracksSource": true,
        "alias": "my-scratch",
        "createdBy": "admin@example.com",
        "createdDate": "2026-01-01T08:00:00.000+0000",
        "expirationDate": "2026-01-08",
        "edition": "Developer",
        "orgName": "Fake Company",
        "status": "Active",
        "isExpired": false,
        "signupUsername": "test-fake1234@example.com",
        "devHubOrgId": "00D000000000001AAA",
        "namespace": null,
        "isDefaultUsername": false,
        "isDefaultDevHubUsername": false,
        "lastUsed": "2026-01-01T09:00:00.000Z"
      }
    ]
  },
  "warnings": []
}
]==],
}
