-- `sf api request rest services/data/v62.0/composite/batch --method POST --body @<file> --header Authorization: Bearer 00D000000000000!NOT_A_SESSION -o my-scratch --json`
--
-- The describe batch with a session Salesforce rejects: the header overrides
-- the token sf sends.
--
-- RECORDED with @salesforce/cli/2.153.5 on 2026-10-16 by scripts/record_fixtures.lua, which
-- replaced tokens, ids, usernames, URLs, timestamps and durations with placeholders.
-- Re-record with `make record-fixtures DEVHUB=<alias>` instead of editing it.
return {
  recorded = true,
  code = 1,
  stdout = [[
{
  "status": 1,
  "result": {
    "statusCode": 401,
    "headers": {
      "date": "FAKE_HEADER_VALUE",
      "content-type": "application/json;charset=UTF-8",
      "transfer-encoding": "FAKE_HEADER_VALUE",
      "connection": "FAKE_HEADER_VALUE",
      "x-sfdc-trace-flags": "FAKE_HEADER_VALUE",
      "permissions-policy": "FAKE_HEADER_VALUE",
      "www-authenticate": "FAKE_HEADER_VALUE",
      "x-content-type-options": "FAKE_HEADER_VALUE",
      "x-robots-tag": "FAKE_HEADER_VALUE",
      "vary": "FAKE_HEADER_VALUE",
      "cache-control": "FAKE_HEADER_VALUE",
      "set-cookie": [
        "FAKE_HEADER_VALUE",
        "FAKE_HEADER_VALUE",
        "FAKE_HEADER_VALUE"
      ],
      "strict-transport-security": "FAKE_HEADER_VALUE",
      "server": "FAKE_HEADER_VALUE",
      "x-sfdc-request-id": "FAKE_HEADER_VALUE",
      "x-request-id": "FAKE_HEADER_VALUE"
    },
    "body": [
      {
        "message": "Session expired or invalid",
        "errorCode": "INVALID_SESSION_ID"
      }
    ]
  },
  "warnings": []
}
]],
}
