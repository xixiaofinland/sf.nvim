local Util = require('sf.util');
local Term = require('sf.term');
local Sf = {}

Sf.last_tests = Util.last_tests

Sf.target_org = Util.target_org

Sf.get = Util.get

-- Copy current file name without dot-after, e.g. copy "Hello" from "Hello.cls"
Sf.copy_apex_name = Util.copy_apex_name

-- From Term module ==========================================================

Sf.toggle = Term.toggle
Sf.open = Term.open
Sf.save_and_push = Term.save_and_push
Sf.retreive = Term.retreive
Sf.cancel = Term.cancel
Sf.go_to_sf_root = Term.go_to_sf_root
Sf.run = Term.run

return Sf
