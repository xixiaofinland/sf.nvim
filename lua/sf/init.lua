local Util = require('sf.util');
local Term = require('sf.term');
local Org = require('sf.org');
local Metadata = require('sf.md');
local Test = require('sf.test');
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

-- From Metadata module ==========================================================

--- Download metadata name list, e.g. Apex names, LWC names, StaticResource names, etc. as Json files into the the project root path "md" folder.
Sf.pull_md_json = Metadata.pull_md_json

--- Choose a specific metadata file to retrieve.
--- Its popup list depends on data retrieved by |retrieve_metadata_lists| in prior.
Sf.list_md_to_retrieve = Metadata.list_md_to_retrieve

--- Pulls defined md files to local json file and list them in telescope for retrieving
--- it is `pull_md_json()` then `list_md_to_retrieve()` in one go.
Sf.pull_and_list_md = Metadata.pull_and_list_md

--- Download metadata-type list, e.g. ApexClass, LWC, Aura, FlexiPage, etc. as a Json file into the project root path "md" folder.
Sf.pull_md_type_json = Metadata.pull_md_type_json

--- Select a specific metadata-type to download all its files. For example, download all ApexClass files.
--- Its popup list depends on data retrieved by |pull_metadata_type_list| in prior.
Sf.list_md_type_to_retrieve = Metadata.list_md_type_to_retrieve

--- Pulls metadata-types to a local json file and list them in telescope for retrieving all corresponding type files
--- `pull_md_type_json()` then `list_md_type_to_retrieve()` in one go.
Sf.pull_and_list_md_type = Metadata.pull_and_list_md_type

--- Use the word under the cursor and attempt to retrieve as a Apex name from target_org.
Sf.retrieve_apex_under_cursor = Metadata.retrieve_apex_under_cursor

-- From Metadata module ==========================================================

--- Open a top window that displays the list of Apex tests in the current file.
--- Allows to select/deselect tests and execute.
Sf.open = Test.open

--- Run the Apex test under the cursor in target_org. The command is sent to SFTerm.
Sf.run_current_test = Test.run_current_test

--- Run all Apex tests in the current Apex file in target_org. The command is sent to SFTerm.
Sf.run_all_tests_in_this_file = Test.run_all_tests_in_this_file

--- Repeat the last executed Apex test command. The command is sent to SFTerm.
Sf.repeat_last_tests = Test.repeat_last_tests

return Sf
