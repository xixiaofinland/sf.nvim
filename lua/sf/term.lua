local S = require('sf')
local TS = require('sf.ts')
local U = require('sf.util')
local t = require('sf.term.terminal'):new()

local M = {}
M.t = t

function M.toggle()
  t:toggle1()
end

function M.open()
  t:open1()
end

function M.save_and_push()
  vim.api.nvim_command('write')
  local cmd = vim.fn.expandcmd('sf project deploy start -d %:p -o ') .. S.get()
  t:run1(cmd)
end

function M.retrieve()
  local cmd = vim.fn.expandcmd('sf project retrieve start -d %:p -o ') .. S.get()
  t:run1(cmd)
end

function M.run_current_test()
  local test_class_name = TS.get_test_class_name()
  U.is_empty(test_class_name)

  local test_name = TS.get_current_test_method_name()
  U.is_empty(test_name)

  local cmd = string.format("sf apex run test --tests %s.%s --result-format human -y -o %s", test_class_name, test_name, S.get())
  S.last_tests = cmd
  t:run(cmd)
end

function M.run_all_tests_in_this_file()
  local test_class_name = TS.get_test_class_name()
  U.is_empty(test_class_name)

  local cmd = string.format("sf apex run test --class-names %s --result-format human -y -o %s", test_class_name, S.get())
  t:run(cmd)
end

function M.cancel()
  t:run('\3')
end

function M.go_to_sf_root()
  local root = U.get_sf_root()
  t:run('cd ' .. root)
end

function M.repeat_last_tests()
  U.is_empty(S.last_tests)

  t:run(S.last_tests)
end

function M.run(c)
  local cmd = vim.fn.expandcmd(c)
  t:run(cmd)
end

-- function M.scrollToEnd()
--   t:run(vim.cmd('$'))
-- end

return M
