local Term = require "sf.term.terminal"
local t = Term:new()
local U = require "sf.term.util"
local TS = require('sf.ts')

local M = {}

function M.toggle()
  t:toggle()
end

function M.saveAndPush()
  vim.api.nvim_command('write')
  local cmd = U.expand_cmd('sf project deploy start  -d %:p ') .. U.get_target_org()
  t:run(cmd)
end

function M.retrieve()
  local cmd = U.expand_cmd('sf project retrieve start  -d %:p ') .. U.get_target_org()
  t:run(cmd)
end

function M.runCurrentTest()
  local test_class_name = TS.get_test_class_name()
  if test_class_name == nil then
    return vim.notify('Not in a test class', vim.log.levels.ERROR)
  end

  local test_name = TS.get_curr_method_name()
  if test_name == nil then
    return vim.notify('Not in a test method', vim.log.levels.ERROR)
  end

  local cmd = "sf apex run test --tests " .. test_class_name .. "." .. test_name .. " --result-format human " .. U.get_target_org()
  t:run(cmd)
end

function M.runAllTestsInCurrentFile()
  local test_class_name = TS.get_test_class_name()
  if test_class_name == nil then
    return vim.notify('Not in a test class', vim.log.levels.ERROR)
  end

  local cmd = "sf apex run test --class-names " .. test_class_name .. " --result-format human " .. U.get_target_org()
  t:run(cmd)
end

function M.run(c)
  local cmd = U.expand_cmd(c)
  t:run(cmd)
end

return M
