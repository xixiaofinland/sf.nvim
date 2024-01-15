local TS = require('sf.ts.ts')
local M = {}
local H = {}
local api = vim.api
local buftype = 'nowrite'
local filetype = 'sf_test_prompt'
-- local last_selected_tests = nil

---@class Prompt
---@field win number
---@field buf number
---@field class string
---@field tests table
---@field type string
local Prompt = {}

function Prompt:new()
  self.__index = self
  local newObj = {
    buf = nil,
    win = nil,
    class = nil,
    tests = nil,
  }
  return setmetatable(newObj, self)
end

function Prompt:open()
  local class = TS.get_test_class_name()
  if class == nil then
    return vim.notify('not in Apex test file', vim.log.levels.ERROR)
  end

  local test_names = TS.get_test_method_names_in_curr_file()
  if next(test_names) == nil then
    return vim.notify('no Apex test found', vim.log.levels.ERROR)
  end

  local tests = {}
  for _, name in pairs(test_names) do
    table.insert(tests, { name, false })
  end

  local buf = self:use_existing_or_create_buf()
  local win = self:use_existing_or_create_win()
  api.nvim_win_set_buf(win, buf)

  api.nvim_buf_set_keymap(buf, 'n', 't', ':lua require("sf.ts").toggle()<CR>', { noremap = true })
  api.nvim_buf_set_keymap(buf, 'n', 'cc', ':lua require("sf.term").runSelectedTests()<CR>', { noremap = true })

  self.buf = buf
  self.win = win
  self.class = class
  self.tests = tests

  vim.bo[buf].modifiable = true
  self:display_test_names()
  vim.bo[buf].modifiable = false
end

function Prompt:display_test_names()
  api.nvim_set_current_win(self.win)
  local names = {}
  for _, val in pairs(self.tests) do
    table.insert(names, '[ ] ' .. val[1])
  end
  api.nvim_buf_set_lines(self.buf, 0, 100, false, names)
end

function Prompt:use_existing_or_create_buf()
  if self.buf and api.nvim_buf_is_loaded(self.buf) then
    return self.buf
  end

  local buf = api.nvim_create_buf(false, false)
  vim.bo[buf].buftype = buftype
  vim.bo[buf].filetype = filetype

  return buf
end

function Prompt:use_existing_or_create_win()
  if self.win and api.nvim_win_is_valid(self.win) then
    api.nvim_set_current_win(self.win)
    return self.win
  end

  api.nvim_command('split')
  return api.nvim_get_current_win()
end

function Prompt:toggle()
  if vim.bo[0].filetype ~= type then
    return vim.notify('not supposed to be used in this filetype', vim.log.levels.ERROR)
  end

  vim.bo[0].modifiable = true

  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local row_index = r - 1

  local curr_toggle_value = api.nvim_buf_get_text(0, row_index, 1, row_index, 2, {})

  local name = self.tests[r][1]
  if curr_toggle_value[1] == 'x' then
    self.tests[r] = { name, false }
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { ' ' })
  else
    self.tests[r] = { name, true }
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { 'x' })
  end

  vim.bo[0].modifiable = false
end

M.get_selected_tests = function()
  local r = {}
  for _, v in pairs(tests) do
    if v[2] then
      table.insert(r, v[1])
    end
  end
  return r
end

M.build_selected_tests_cmd = function()
  if test_class_name == nil or next(tests) == nil then
    return vim.notify('no test class name or tests', vim.log.levels.ERROR)
  end

  local t = ''
  local selected_test = M.get_selected_tests()
  for _, test in pairs(selected_test) do
    t = t .. '-t ' .. test_class_name .. '.' .. test .. ' '
  end
  last_selected_tests = selected_test

  local cmd = 'sf apex run test ' .. t .. "--result-format human -y "
  last_selected_tests = cmd
  return cmd
end

M.get_last_selected_tests = function()
  if last_selected_tests == nil then
    return vim.notify('no last selected test', vim.log.levels.ERROR)
  end
  return last_selected_tests
end

------------- helper -----------------------
-- H.removekey = function(table, key)
--    local element = table[key]
--    table[key] = nil
--    return element
-- end

H.is_open_already = function(id)
  local win_num = vim.fn.win_findbuf(id)
  if win_num == nil then
    return false
  end
  return true
end

return Prompt
