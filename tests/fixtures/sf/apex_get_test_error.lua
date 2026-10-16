-- `sf apex get test -i 707000000000000 -c --json -o my-scratch`
--
-- `apex get test` failing: the error payload carries no coverage.
--
-- RECORDED with @salesforce/cli/2.153.5 on 2026-10-16 by scripts/record_fixtures.lua, which
-- replaced tokens, ids, usernames, URLs, timestamps and durations with placeholders.
-- Re-record with `make record-fixtures DEVHUB=<alias>` instead of editing it.
return {
  recorded = true,
  code = 1,
  stdout = [[
{
  "name": "Error",
  "message": "No test results were found for test run 707000000000000",
  "exitCode": 1,
  "context": "Test",
  "stack": "Error: No test results were found for test run 707000000000000\n    at SfCommandError.from (file:///home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@salesforce/sf-plugins-core/lib/SfCommandError.js:48:16)\n    at Test.catch (file:///home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@salesforce/sf-plugins-core/lib/sfCommand.js:333:47)\n    at Test._run (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@oclif/core/lib/command.js:187:29)\n    at process.processTicksAndRejections (node:internal/process/task_queues:103:5)\n    at async Config.runCommand (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@oclif/core/lib/config/config.js:392:25)\n    at async run (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@oclif/core/lib/main.js:95:16)\n    at async file:///home/user/.npm-global/lib/node_modules/@salesforce/cli/bin/run.js:15:1",
  "cause": "Error: No test results were found for test run 707000000000000\n    at AsyncTests.checkRunStatus (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@salesforce/apex-node/lib/src/tests/asyncTests.js:300:19)\n    at process.processTicksAndRejections (node:internal/process/task_queues:103:5)\n    at async AsyncTests.reportAsyncResults (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@salesforce/apex-node/lib/src/tests/asyncTests.js:221:29)\n    at async TestService.reportAsyncResults (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@salesforce/apex-node/lib/src/tests/testService.js:287:20)\n    at async TestGetBase.execute (file:///home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@salesforce/plugin-apex/lib/shared/TestGetBase.js:26:24)\n    at async Test._run (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@oclif/core/lib/command.js:183:22)\n    at async Config.runCommand (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@oclif/core/lib/config/config.js:392:25)\n    at async run (/home/user/.npm-global/lib/node_modules/@salesforce/cli/node_modules/@oclif/core/lib/main.js:95:16)\n    at async file:///home/user/.npm-global/lib/node_modules/@salesforce/cli/bin/run.js:15:1",
  "warnings": [],
  "code": "1",
  "status": 1,
  "commandName": "Test"
}
]],
}
