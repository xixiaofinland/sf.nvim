-- `sf org display -o devhub --json`
--
-- SYNTHETIC: not captured from a real org. Shaped after `OrgDisplayReturn` in
-- salesforcecli/plugin-org src/shared/orgTypes.ts, as returned by
-- src/commands/org/display.ts. Replace with a real, scrubbed capture and set
-- `recorded = true`.
return {
  recorded = false,
  code = 0,
  stdout = [==[
{
  "status": 0,
  "result": {
    "id": "00D000000000001AAA",
    "apiVersion": "62.0",
    "accessToken": "00D000000000001AAA!FAKE_ACCESS_TOKEN_DEVHUB",
    "instanceUrl": "https://fake-company.my.salesforce.com",
    "username": "admin@example.com",
    "clientId": "PlatformCLI",
    "connectedStatus": "Connected",
    "alias": "devhub"
  },
  "warnings": []
}
]==],
}
