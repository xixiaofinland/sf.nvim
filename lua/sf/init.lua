--- *sf.nvim* Salesforce development plugin
--- *SfNvim*
---
--- MIT License Copyright (c) 2024 Xi Xiao
---

local Util = require('sf.util')
local Term = require('sf.term')
local Org = require('sf.org')
local Metadata = require('sf.md')
local Test = require('sf.test')
local Cfg = require('sf.config')
local Sf = {}

--- Before using this plugin, it's mandatory to invoke this function by "require'sf'.setup()".
---@param config table|nil Optional config table to overwrite default settings.
Sf.setup = Cfg.setup


--- get the value of the plugin internal variable "target_org".
--- "target_org" is automatically set by |Sf.fetch_org_list| when Nvim is intitiated
--- or manually by |Sf.set_target_org|.
Sf.get_target_org = Util.get

-- A convenient way to quickly copy file name trimming dot-after, e.g. copy "Hello" from "Hello.cls"
Sf.copy_apex_name = Util.copy_apex_name

-- From Term module ==========================================================

--- Toggle the SFTerm float window.
Sf.toggle_term = Term.toggle

--- Save the file in the current buffer and push to target_org.
Sf.save_and_push = Term.save_and_push

--- Retrieve the file in the current buffer from target_org.
Sf.retrieve = Term.retrieve

--- Retrieve the file in the current buffer as a manifest from target_org
Sf.retrieve_package = Term.retrieve_package

--- Run the file in the current buffer as anonymous apex in target_org
Sf.run_anonymous = Term.run_anonymous

--- Run the query defined in current buffer in target_org
Sf.run_query = Term.run_query

--- Run the tooling API query defined in the current buffer in target_org
Sf.run_tooling_query = Term.run_tooling_query

--- Terminate the running command in SFTerm.
Sf.cancel = Term.cancel

--- Enter the sf project root path in SFTerm.
Sf.go_to_sf_root = Term.go_to_sf_root

--- Allows to pass the user defined command into SFTerm.
Sf.run = Term.run

-- From Org module ==========================================================

--- Run "sf org list" command under the hood and stores the org list.
--- If a target_org is found, the value is saved into "require('sf.util').target_org", an internal variable.
Sf.fetch_org_list = Org.fetch_org_list

--- Display the list of available orgs, and allow to define the target_org.
--- Run "sf config set target-org" command under the hood to set the target_org.
Sf.set_target_org = Org.set_target_org

--- Salesforce sf command allows users to define a global target_org.
--- Run "sf config set target-org --global " command under the hood.
Sf.set_global_target_org = Org.set_global_target_org

--- Fetch the file in the current buffer from target_org and display in the Nvim diff mode.
--- The left window displays the target_org verison, the right window displays the local verison.
Sf.diff_in_target_org = Org.diff_in_target_org

--- Similar to |Sf.diff_in_target_org|, you can choose which org to diff with.
--- The left window displays the org verison, the right window displays the local verison.
Sf.diff_in_org = Org.diff_in_org

-- From Metadata module ==========================================================

--- Download metadata name list, e.g. Apex names, LWC names, StaticResource names, etc. as Json files into the the project root path "md" folder.
Sf.pull_md_json = Metadata.pull_md_json

--- Choose a specific metadata file to retrieve.
--- Its popup list depends on data retrieved by |Sf.retrieve_metadata_lists| in prior.
Sf.list_md_to_retrieve = Metadata.list_md_to_retrieve

--- Pull pre-defined metadata files to local and list them in telescope for further retrieving
--- It's |Sf.pull_md_json| and |Sf.list_md_to_retrieve| in one go.
Sf.pull_and_list_md = Metadata.pull_and_list_md

--- Download metadata-type list, e.g. ApexClass, LWC, Aura, FlexiPage, etc. as a Json file into the project root path "md" folder.
Sf.pull_md_type_json = Metadata.pull_md_type_json

--- Select a specific metadata-type to download all its files. For example, download all ApexClass files.
--- Its popup list depends on data retrieved by |Sf.pull_metadata_type_list| in prior.
Sf.list_md_type_to_retrieve = Metadata.list_md_type_to_retrieve

--- Pull the list of metadata-types into a local json file, and list them in a pop-up.
--- It's |Sf.pull_md_type_json| and |Sf.list_md_type_to_retrieve| in one go.
Sf.pull_and_list_md_type = Metadata.pull_and_list_md_type

--- Uses the word under the cursor as Apex name to attempt to retreive from the org.
--- A convenient way to quickly pull Apex into local.
Sf.retrieve_apex_under_cursor = Metadata.retrieve_apex_under_cursor

-- From Test module ==========================================================

--- Open a top-split window to display the Apex tests in the current file.
--- This window also enables to select tests from multiple files.
Sf.open_test_select = Test.open

--- Run the Apex test under the cursor.
--- It uses Treesitter to determine @IsTest method.
Sf.run_current_test = Test.run_current_test

--- Run all Apex tests in the current Apex file.
Sf.run_all_tests_in_this_file = Test.run_all_tests_in_this_file

--- A convenient way to repeat the last executed Apex test command.
Sf.repeat_last_tests = Test.repeat_last_tests

return Sf
