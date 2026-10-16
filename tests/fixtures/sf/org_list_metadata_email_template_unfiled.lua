-- `sf org list metadata -m EmailTemplate --folder unfiled$public -o my-scratch --json`
--
-- The email templates in no folder, which the folder list names unfiled$public.
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
      "createdById": "005000000000002AAA",
      "createdByName": "Fake User 2",
      "createdDate": "2026-01-01T00:00:00.000Z",
      "fileName": "email/unfiled$public/CommerceReorderPortalInvitation.email",
      "fullName": "unfiled$public/CommerceReorderPortalInvitation",
      "id": "00X000000000002AAA",
      "lastModifiedById": "005000000000002AAA",
      "lastModifiedByName": "Fake User 2",
      "lastModifiedDate": "2026-01-01T00:00:00.000Z",
      "manageableState": "unmanaged",
      "type": "EmailTemplate"
    }
  ],
  "warnings": []
}
]],
}
