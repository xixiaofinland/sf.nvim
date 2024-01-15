local Term = require "sf.term.terminal"
local t = Term:new()
local Org = require "sf.org"
local TS = require('sf.ts')
local Test = require('sf.test')

local M = {}

M.lastTests = nil

function M.toggle()
  t:toggle()
end

function M.saveAndPush()
  vim.api.nvim_command('write')
  local cmd = vim.fn.expandcmd('sf project deploy start  -d %:p ') .. Org.get()
  t:run(cmd)
end

function M.retrieve()
  local cmd = vim.fn.expandcmd('sf project retrieve start  -d %:p ') .. Org.get()
  t:run(cmd)
end

function M.runCurrentTest()
  local test_class_name = TS.get_test_class_name()
  if test_class_name == nil then
    return vim.notify('Not in a test class', vim.log.levels.ERROR)
  end

  local test_name = TS.get_current_test_method_name()
  if test_name == nil then
    return vim.notify('Not in a test method', vim.log.levels.ERROR)
  end

  local cmd = "sf apex run test --tests " .. test_class_name .. "." .. test_name .. " --result-format human -y " .. Org.get()
  t:run(cmd)
end

function M.runAllTestsInCurrentFile()
  local test_class_name = TS.get_test_class_name()
  if test_class_name == nil then
    return vim.notify('Not in a test class', vim.log.levels.ERROR)
  end

  local cmd = "sf apex run test --class-names " .. test_class_name .. " --result-format human -y " .. Org.get()
  t:run(cmd)
end

function M.cancel()
  t:run('\3')
end

function M.scrollToEnd()
  t:run(vim.cmd('$'))
end

function M.runSelectedTests()

  print(Test.build_selected_tests_cmd()) 
  local cmd = Test.build_selected_tests_cmd() .. Org.get()
  M.lastTests = cmd
  t:run(cmd)
end

function M.repeatLastTests()
  if M.lastTests == nil then
    return vim.notify('no last selected tests?', vim.log.levels.ERROR)
  end

  t:run(M.lastTests)
end

function M.run(c)
  local cmd = vim.fn.expandcmd(c)
  t:run(cmd)
end

return M
