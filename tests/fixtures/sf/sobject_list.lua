-- `sf sobject list -o devhub -s ALL --json`
--
-- SYNTHETIC: not captured from a real org. Shaped after
-- salesforcecli/plugin-schema src/commands/sobject/list.ts, whose result is a
-- sorted array of sObject API names. A real org returns hundreds; this keeps a
-- few, including names the refresh filters out (Share/History/Feed/Event).
-- Replace with a real, scrubbed capture and set `recorded = true`.
return {
  recorded = false,
  code = 0,
  stdout = [==[
{
  "status": 0,
  "result": [
    "Account",
    "AccountFeed",
    "AccountHistory",
    "AccountShare",
    "Contact",
    "Invoice__c",
    "MyPlatform__e"
  ],
  "warnings": []
}
]==],
}
