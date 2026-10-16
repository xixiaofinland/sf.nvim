-- `sf org list --json --skip-connection-status`
--
-- Every org this machine is authorised to, scrubbed; the scratch org is
-- my-scratch, the project's default target org, and the Dev Hub devhub.
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
    "other": [],
    "sandboxes": [],
    "nonScratchOrgs": [
      {
        "accessToken": "00D000000000000!FAKE_ACCESS_TOKEN_1",
        "orgId": "00D000000000002AAA",
        "loginUrl": "https://fake-company-3.my.salesforce.com",
        "privateKey": "/home/user/.config/sf-nvim/server.key",
        "clientId": "FAKE_CLIENT_ID_1",
        "instanceUrl": "https://fake-company-2.my.salesforce.com",
        "isDevHub": true,
        "username": "user2@example.com",
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 0:00:00 AM",
        "name": "Fake Company 2",
        "instanceName": "SWE126",
        "namespacePrefix": null,
        "isSandbox": false,
        "isScratch": false,
        "trailExpirationDate": null,
        "orgEdition": "Developer Edition",
        "alias": "devhub",
        "isDefaultDevHubUsername": true,
        "isDefaultUsername": false,
        "lastUsed": "2026-01-01T00:00:00.000Z",
        "defaultMarker": "(D)"
      }
    ],
    "devHubs": [
      {
        "accessToken": "00D000000000000!FAKE_ACCESS_TOKEN_1",
        "orgId": "00D000000000002AAA",
        "loginUrl": "https://fake-company-3.my.salesforce.com",
        "privateKey": "/home/user/.config/sf-nvim/server.key",
        "clientId": "FAKE_CLIENT_ID_1",
        "instanceUrl": "https://fake-company-2.my.salesforce.com",
        "isDevHub": true,
        "username": "user2@example.com",
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 0:00:00 AM",
        "name": "Fake Company 2",
        "instanceName": "SWE126",
        "namespacePrefix": null,
        "isSandbox": false,
        "isScratch": false,
        "trailExpirationDate": null,
        "orgEdition": "Developer Edition",
        "alias": "devhub",
        "isDefaultDevHubUsername": true,
        "isDefaultUsername": false,
        "lastUsed": "2026-01-01T00:00:00.000Z",
        "defaultMarker": "(D)"
      }
    ],
    "scratchOrgs": [
      {
        "accessToken": "00D000000000000!FAKE_ACCESS_TOKEN_1",
        "instanceUrl": "https://fake-company.my.salesforce.com",
        "orgId": "00D000000000001AAA",
        "username": "admin@example.com",
        "loginUrl": "https://fake-company.my.salesforce.com",
        "clientId": "PlatformCLI",
        "isDevHub": false,
        "instanceApiVersion": "62.0",
        "instanceApiVersionLastRetrieved": "1/1/2026, 0:00:00 AM",
        "name": "Fake Company",
        "instanceName": "SWE30S",
        "namespacePrefix": null,
        "isSandbox": false,
        "isScratch": true,
        "trailExpirationDate": "2026-01-01T00:00:00.000+0000",
        "orgEdition": "Developer Edition",
        "devHubUsername": "user2@example.com",
        "created": "1792178713000",
        "expirationDate": "2026-01-01",
        "createdOrgInstance": "SWE30S",
        "tracksSource": true,
        "alias": "my-scratch",
        "isDefaultDevHubUsername": false,
        "isDefaultUsername": true,
        "lastUsed": "2026-01-01T00:00:00.000Z",
        "signupUsername": "admin@example.com",
        "createdBy": "user2@example.com",
        "createdDate": "2026-01-01T00:00:00.000+0000",
        "devHubOrgId": "00D000000000002AAA",
        "devHubId": "00D000000000002AAA",
        "attributes": {
          "type": "ScratchOrgInfo",
          "url": "/services/data/v62.0/sobjects/ScratchOrgInfo/2SRd2000001BNC1GAO"
        },
        "orgName": "Fake Company",
        "edition": "Developer",
        "status": "Active",
        "isExpired": false,
        "namespace": null,
        "defaultMarker": "(U)"
      }
    ]
  },
  "warnings": []
}
]],
}
