-- `sf api request rest services/data/v62.0/composite/batch --method POST
-- --body @<file> -o devhub --json` when Salesforce rejects the session.
--
-- SYNTHETIC: not captured from a real org. salesforcecli/plugin-api
-- src/shared/shared.ts prints the response and sets the exit code to 1 for any
-- status >= 400; the body is the REST API's INVALID_SESSION_ID error. Replace
-- with a real, scrubbed capture and set `recorded = true`.
return {
  recorded = false,
  code = 1,
  stdout = [==[
{
  "status": 1,
  "result": {
    "statusCode": 401,
    "headers": { "content-type": "application/json;charset=UTF-8" },
    "body": [
      { "message": "Session expired or invalid", "errorCode": "INVALID_SESSION_ID" }
    ]
  },
  "warnings": []
}
]==],
}
