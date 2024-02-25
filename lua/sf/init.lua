local U = require('sf.util');
local Sf = {}

Sf.last_tests = U.last_tests

Sf.target_org = U.target_org

Sf.get = function()
  U.is_empty(Sf.target_org)

  return Sf.target_org
end

-- Copy current file name without dot-after, e.g. copy "Hello" from "Hello.cls"
Sf.copy_apex_name = U.copy_apex_name

return Sf
