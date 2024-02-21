--- *SFTest* Test module
--- *Sf test*
---
--- Features:
---
--- - Apex test related features

local S = require('sf')
local T = require('sf.term')
local TS = require('sf.ts')
local U = require('sf.util')
local p = require('sf.test.prompt'):new()
local H = {}
local Test = {}

--- Open a top window that displays the list of Apex tests in the current file.
--- Allows to select/deselect tests and execute.
Test.open = function()
  p:open()
end

--- Run the Apex test under the cursor in target_org. The command is sent to SFTerm.
Test.run_current_test = function()
  local test_class_name = TS.get_test_class_name()
  U.is_empty(test_class_name)

  local test_name = TS.get_current_test_method_name()
  U.is_empty(test_name)

  local cmd = string.format("sf apex run test --tests %s.%s --result-format human -y -o %s", test_class_name, test_name,
    S.get())
  S.last_tests = cmd
  T.run(cmd)
end

--- Run all Apex tests in the current Apex file in target_org. The command is sent to SFTerm.
Test.run_all_tests_in_this_file = function()
  local test_class_name = TS.get_test_class_name()
  U.is_empty(test_class_name)

  local cmd = string.format("sf apex run test --class-names %s --result-format human -y -o %s", test_class_name, S.get())
  T.run(cmd)
end

--- Repeat the last executed Apex test command. The command is sent to SFTerm.
Test.repeat_last_tests = function()
  U.is_empty(S.last_tests)

  T:run(S.last_tests)
end

--- Open a top window that displays the list of Apex tests in the selected file.
--- Allows to add tests to execute.
Test.open_tests_in_selected = function()
  local opts = {
    attach_mappings = H.tele_pick_test_file,
    prompt_title = 'Select Test File',
    search_file = '*.cls', -- TODO:
  }
  require('telescope.builtin').find_files(opts)
end

-- local methods

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local function open_selected(abs_file_name)
  local bufnr = vim.api.nvim_create_buf(false, false)
  vim.api.nvim_buf_call(bufnr, function()
    vim.cmd('edit ' .. abs_file_name)
    p:open()
  end)
end

H.tele_pick_test_file = function(prompt_bufnr, map)
  actions.select_default:replace(function()
    actions.close(prompt_bufnr)
    local selected_file_path = action_state.get_selected_entry().path
    open_selected(selected_file_path)
  end)
  return true
end

return Test
