local Util = require('sf.util');
local Term = require('sf.term');
local Org = require('sf.org');
local Sf = {}

Sf.last_tests = Util.last_tests

Sf.target_org = Util.target_org

Sf.get = Util.get

-- Copy current file name without dot-after, e.g. copy "Hello" from "Hello.cls"
Sf.copy_apex_name = Util.copy_apex_name

-- From Term module ==========================================================

--- Toggle the SFTerm float window.
Sf.toggle = Term.toggle

--- Open the SFTerm float window.
Sf.open = Term.open

--- Save the file in the current buffer and push to target_org. The command is sent to SFTerm.
Sf.save_and_push = Term.save_and_push

--- Retrieve the file in the current buffer from target_org. The command is sent to SFTerm.
Sf.retreive = Term.retreive

--- Terminate the running command in SFTerm.
Sf.cancel = Term.cancel

--- Enter the sf project root path in SFTerm.
Sf.go_to_sf_root = Term.go_to_sf_root

--- Allows to pass the user defined command into SFTerm.
Sf.run = Term.run

-- From Term module ==========================================================

--- It runs "sf org list" command under the hood and stores the org list.
--- If a target_org is found, the value is saved into "target_org" variable.
Sf.fetch_org_list = Org.fetch_org_list

--- It displays the list of orgs, and allows you to define the target_org.
--- It runs "sf config set target-org" command under the hood to set the target_org.
Sf.set_target_org = Org.set_target_org

--- sf command allows to define a global target_org.
--- It runs "sf config set target-org --global " command under the hood.
Sf.set_global_target_org = Org.set_global_target_org

--- It fetches the file in the current buffer from target_org and display in the Nvim diff mode.
--- The left window displays the target_org verison, the right window displays the local verison.
Sf.diff_in_target_org = Org.diff_in_target_org

--- Similar to |diff_in_target_org|, you can choose which org to diff with.
--- The left window displays the org verison, the right window displays the local verison.
Sf.diff_in_org = Org.diff_in_org

return Sf
