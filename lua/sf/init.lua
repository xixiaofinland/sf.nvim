local U = require('sf.util');
local Sf = {}

Sf.last_tests = ''

Sf.target_org = ''

Sf.get = function()
  U.is_empty(Sf.target_org)

  return Sf.target_org
end

return Sf
