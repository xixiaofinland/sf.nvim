local S = require('sf')
local TS = require('sf.ts')
local U = require('sf.util')
local t = require('sf.term.terminal'):new()

local Term = {}

--- toggle the SFTerm float window.
function Term.toggle()
  t:toggle()
end

--- open the SFTerm float window.
function Term.open()
  t:open()
end

--- Save the file in the current buffer and push to target_org. The command is sent to SFTerm.
function Term.save_and_push()
  vim.api.nvim_command('e') -- reload file or write might invoke y/n pop-up in Ex
  vim.api.nvim_command('write')
  local cmd = vim.fn.expandcmd('sf project deploy start -d %:p -o ') .. S.get()
  t:run(cmd)
end

--- Retrieve the file in the current buffer from target_org. The command is sent to SFTerm.
function Term.retrieve()
  local cmd = vim.fn.expandcmd('sf project retrieve start -d %:p -o ') .. S.get()
  t:run(cmd)
end

--- Run the Apex test under the cursor in target_org. The command is sent to SFTerm.
function Term.run_current_test()
  local test_class_name = TS.get_test_class_name()
  U.is_empty(test_class_name)

  local test_name = TS.get_current_test_method_name()
  U.is_empty(test_name)

  local cmd = string.format("sf apex run test --tests %s.%s --result-format human -y -o %s", test_class_name, test_name, S.get())
  S.last_tests = cmd
  t:run(cmd)
end

--- Run all Apex tests in the current Apex file in target_org. The command is sent to SFTerm.
function Term.run_all_tests_in_this_file()
  local test_class_name = TS.get_test_class_name()
  U.is_empty(test_class_name)

  local cmd = string.format("sf apex run test --class-names %s --result-format human -y -o %s", test_class_name, S.get())
  t:run(cmd)
end

--- Terminate the running command in SFTerm.
function Term.cancel()
  t.is_running = false -- set the flag to stop the running task
  t:run('\3')
end

--- Enter the sf project root path in SFTerm.
function Term.go_to_sf_root()
  local root = U.get_sf_root()
  t:run('cd ' .. root)
end

--- Repeat the last executed Apex test command. The command is sent to SFTerm.
function Term.repeat_last_tests()
  U.is_empty(S.last_tests)

  t:run(S.last_tests)
end

--- Allows to pass the user defined command into SFTerm.
function Term.run(c)
  local cmd = vim.fn.expandcmd(c)
  t:run(cmd)
end

return Term
