-- `sf org list metadata -m EmailTemplate --folder SfNvimTemplates -o my-scratch --json`
--
-- The email templates in one folder.
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
  "result": [
    {
      "createdById": "005000000000001AAA",
      "createdByName": "Fake Admin",
      "createdDate": "2026-01-01T00:00:00.000Z",
      "fileName": "email/SfNvimTemplates/Welcome.email",
      "fullName": "SfNvimTemplates/Welcome",
      "id": "00X000000000001AAA",
      "lastModifiedById": "005000000000001AAA",
      "lastModifiedByName": "Fake Admin",
      "lastModifiedDate": "2026-01-01T00:00:00.000Z",
      "manageableState": "unmanaged",
      "type": "EmailTemplate"
    }
  ],
  "warnings": []
}
]],
}
