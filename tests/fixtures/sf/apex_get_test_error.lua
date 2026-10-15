-- `sf apex get test -i 7070000000FAKE1 -c --json` failing, e.g. when the
-- org's session has expired: the error payload carries no coverage.
--
-- SYNTHETIC: not captured from a real org. Shaped after the `--json` error
-- output of @salesforce/sf-plugins-core's SfCommand (`toErrorJson`): name,
-- message, exitCode, status, context and warnings. Replace with a real,
-- scrubbed capture and set `recorded = true`.
return {
  recorded = false,
  code = 1,
  stdout = [==[
{
  "name": "INVALID_SESSION_ID",
  "message": "Session expired or invalid",
  "exitCode": 1,
  "context": "Test",
  "commandName": "Test",
  "status": 1,
  "code": "INVALID_SESSION_ID",
  "warnings": []
}
]==],
}
