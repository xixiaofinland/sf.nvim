-- `sf apex run test -n SfProjectTest -r human -w 5 -c -o my-scratch`
--
-- The form the plugin runs in its terminal; it reads the Test Run Id line to
-- fetch coverage.
--
-- RECORDED with @salesforce/cli/2.153.5 on 2026-10-16 by scripts/record_fixtures.lua, which
-- replaced tokens, ids, usernames, URLs, timestamps and durations with placeholders.
-- Re-record with `make record-fixtures DEVHUB=<alias>` instead of editing it.
return {
  recorded = true,
  code = 0,
  stdout = [[
=== Test Results
TEST NAME                         OUTCOME  MESSAGE  RUNTIME (MS)
────────────────────────────────  ───────  ───────  ────────────
SfProjectTest.constructsWithName  Pass              0          
SfProjectTest.constructsWithNull  Pass              0           


=== Apex Code Coverage by Class
CLASSES    PERCENT  UNCOVERED LINES
─────────  ───────  ───────────────
SfProject  67%      12,13          




=== Test Summary
NAME                 VALUE                        
───────────────────  ─────────────────────────────
Outcome              Passed                       
Tests Ran            2                            
Pass Rate            100%                         
Fail Rate            0%                           
Skip Rate            0%                           
Test Run Id          707000000000001              
Test Setup Time      0 ms                         
Test Execution Time  0 ms                        
Test Total Time      0 ms                        
Org Id               00D000000000001AAA           
Username             admin@example.com
Org Wide Coverage    66%                          

]],
}
