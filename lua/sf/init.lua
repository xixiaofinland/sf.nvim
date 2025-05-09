--- *sf.nvim* Salesforce development plugin
--- *SfNvim*
---
--- MIT License Copyright (c) 2024 Xi Xiao
---

local Util = require("sf.util")
local Term = require("sf.term")
local Org = require("sf.org")
local Metadata = require("sf.md")
local Test = require("sf.test")
local Ctags = require("sf.ctags")
local Project = require("sf.project")
local Sf = {}

--- Before using this plugin, it's mandatory to invoke this function by "require'sf'.setup()".
---@param opt table|nil Optional config table to overwrite default settings.
Sf.setup = function(opt)
  require("sf.config").setup(opt)
end

--- get the value of the plugin internal variable "target_org".
--- "target_org" is automatically set by |Sf.fetch_org_list| when Nvim is intitiated
--- or manually by |Sf.set_target_org|.
Sf.get_target_org = Util.get

--- Display the Apex test coverage percent for the current Apex file
Sf.covered_percent = Test.covered_percent

--- A convenient way to quickly copy file name trimming dot-after, e.g. copy "Hello" from "Hello.cls"
Sf.copy_apex_name = Util.copy_apex_name

--- get latest code coverage percentage info for the current Apex
Sf.refresh_current_file_covered_percent = Test.refresh_current_file_covered_percent

-- From Term module ==========================================================

--- Toggle the SFTerm float window.
Sf.toggle_term = Term.toggle

--- Save the file in the current buffer and push to target_org.
--- Accepts one string parameter to add extra parameters.
--- For example, to add `-c` parameter, you can define hotkey as:
--- vim.keymap.set('n', '<leader>sg', require('sf').save_and_push('-c') end, { desc = 'custom key' })
Sf.save_and_push = Term.save_and_push

--- Run `sf project deploy start` against the target_org
--- Accepts one string parameter to add extra parameters.
--- For example, to add `-c` parameter, you can define hotkey as:
--- vim.keymap.set('n', '<leader>sg', require('sf').push_delta('-c') end, { desc = 'custom key' })
Sf.push_delta = Term.push_delta

--- Retrieve the file in the current buffer from target_org.
--- Accepts one string parameter to add extra parameters.
--- For example, to add `-c` parameter, you can define hotkey as:
--- vim.keymap.set('n', '<leader>sg', require('sf').retrieve('-c') end, { desc = 'custom key' })
Sf.retrieve = Term.retrieve

--- Run `sf project retrieve start` against the target_org
--- Accepts one string parameter to add extra parameters.
--- For example, to add `-c` parameter, you can define hotkey as:
--- vim.keymap.set('n', '<leader>sg', require('sf').retrieve_delta('-c') end, { desc = 'custom key' })
Sf.retrieve_delta = Term.retrieve_delta

--- Retrieve the file in the current buffer as a manifest from target_org
Sf.retrieve_package = Term.retrieve_package

--- Run the file in the current buffer as anonymous apex in target_org
Sf.run_anonymous = Term.run_anonymous

--- Run the query defined in current buffer in target_org
Sf.run_query = Term.run_query

--- Run the tooling API query defined in the current buffer in target_org
Sf.run_tooling_query = Term.run_tooling_query

--- Run visual mode highlight selected text as SOQL in the term
Sf.run_highlighted_soql = Term.run_highlighted_soql

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
--- The left window displays the target_org verison, the right window displays the remote org verison
Sf.diff_in_target_org = Org.diff_in_target_org

--- Similar to |Sf.diff_in_target_org|, you can choose which org to diff with.
--- The left window displays the local verison, the right window displays the remote org verison
Sf.diff_in_org = Org.diff_in_org

--- Open the target_org in browser
Sf.org_open = Org.open

--- Open the current file in the target_org in browser
Sf.org_open_current_file = Org.open_current_file

--- Get a list of logs from the org, and choose one to download and open
Sf.pull_log = Org.pull_log

-- From Project module ==========================================================

--- Returns the current package directory. By default, the plugin uses the default package from sfdx-project.json.
--- If no packages are found, falls back to the value specified in 'default_dir'. If multiple packages are available,
--- you can override the current working package using |Sf.set_current_package|
Sf.get_current_package_dir = Project.get_current_package_dir

--- Set the current package directory.
Sf.set_current_package_dir = Project.set_current_package_dir

--- Prompts the user for a package to use for the project. Only useful if you have multiple package directories in your
--- sfdx-project.json file.
Sf.set_current_package = Project.set_current_package

-- From Metadata module ==========================================================

--- Download metadata name list, e.g. Apex names, LWC names, StaticResource names, etc. as Json files into the the project root path "md" folder.
Sf.pull_md_json = Metadata.pull_md_json

--- Choose a specific metadata file to retrieve.
--- Its popup list depends on data retrieved by |Sf.retrieve_metadata_lists| in prior.
Sf.list_md_to_retrieve = Metadata.list_md_to_retrieve

--- Download metadata-type list, e.g. ApexClass, LWC, Aura, FlexiPage, etc. as a Json file into the project root path "md" folder.
Sf.pull_md_type_json = Metadata.pull_md_type_json

--- Select a specific metadata-type to download all its files. For example, download all ApexClass files.
--- Its popup list depends on data retrieved by |Sf.pull_metadata_type_list| in prior.
Sf.list_md_type_to_retrieve = Metadata.list_md_type_to_retrieve

--- Uses the word under the cursor as Apex name to attempt to retreive from the org.
--- A convenient way to quickly pull Apex into local.
Sf.retrieve_apex_under_cursor = Metadata.retrieve_apex_under_cursor

--- Creates a new Apex Class using an input name or prompting the user to enter one
Sf.create_apex_class = Metadata.create_apex_class

--- Creates a new Aura Bundle using an input name or prompting the user to enter one
Sf.create_aura_bundle = Metadata.create_aura_bundle

--- Creates a new LWC Bundle using an input name or prompting the user to enter one
Sf.create_lwc_bundle = Metadata.create_lwc_bundle

--- Creates an apex trigger using an input name or prompting the user to enter one
Sf.create_trigger = Metadata.create_trigger

-- From Test module ==========================================================

--- Open a top-split window to display the Apex tests in the current file.
Sf.open_test_select = Test.open

--- Run the Apex test under the cursor.
--- It uses Treesitter to determine @IsTest method.
Sf.run_current_test = Test.run_current_test

--- Same as `run_current_test`, but with code coverage info in the result.
Sf.run_current_test_with_coverage = Test.run_current_test_with_coverage

--- Run all Apex tests in the current Apex file.
Sf.run_all_tests_in_this_file = Test.run_all_tests_in_this_file

--- Run all Apex tests in the current Apex file, but with code coverage info in the result.
Sf.run_all_tests_in_this_file_with_coverage = Test.run_all_tests_in_this_file_with_coverage

--- A convenient way to repeat the last executed Apex test command.
Sf.repeat_last_tests = Test.repeat_last_tests

--- Run all local tests in target_org
Sf.run_local_tests = Test.run_local_tests

--- Run all jest tests in project
Sf.run_all_jests = Test.run_all_jests

--- Run all jest tests in current file
Sf.run_jest_file = Test.run_jest_file

--- show sign icons to indicates uncovered lines from the latest test running result.
Sf.toggle_sign = Test.toggle_sign

--- When code coverage sign icon is enabled on the current buffer, the cursor jumps to the next uncovered line
Sf.uncovered_jump_forward = Test.uncovered_jump_forward

--- When code coverage sign icon is enabled on the current buffer, the cursor jumps to the previous uncovered line
Sf.uncovered_jump_backward = Test.uncovered_jump_backward

-- From Ctags module ==========================================================

--- Create tags file in the root path by using universal ctags cli tool.
Sf.create_ctags = Ctags.create

--- Create tags file in the root path and list them by fzf plugin.
--- When fzf is not found, the command exists with an error msg.
Sf.create_and_list_ctags = Ctags.create_and_list

return Sf
