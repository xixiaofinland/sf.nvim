local TS = require('sf.ts.ts')
local M = {}
local H = {}
local api = vim.api
-- local last_selected_tests = nil

---@class Prompt
---@field win number
---@field buf number
---@field class string
---@field tests table
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

  api.nvim_buf_set_keymap(buf, 'n', 't', ':lua require("sf.ts.test_buf").toggle()<CR>', { noremap = true })
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
  api.nvim_buf_set_option(buf, 'buftype', 'nowrite')

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

-----------------------------

M.open = function()
  if buf_id == nil then
    api.nvim_command('split ' .. buf_name)
    buf_id = api.nvim_win_get_buf(0)
    win_id = api.nvim_tabpage_get_win(0)

    M.init_tests_table(test_names)
    M.set_test_names_in_buf(test_names)
    api.nvim_buf_set_keymap(0, 'n', 't', ':lua require("sf.ts.test_buf").toggle()<CR>', { noremap = true })
    api.nvim_buf_set_keymap(0, 'n', 'cc', ':lua require("sf.term").runSelectedTests()<CR>', { noremap = true })

    vim.bo[0].modifiable = false

    -- else if H.is_open_already(buf_id)
  elseif win_id ~= nil and H.is_open_already(win_id) then
    api.nvim_set_current_win(win_id)
  end
end

M.init_tests_table = function(test_names)
  tests = {}
  for _, val in pairs(test_names) do
    table.insert(tests, { val, false })
  end
end

M.set_test_names_in_buf = function(test_names)
  local display_names = {}
  for _, val in pairs(test_names) do
    table.insert(display_names, '[ ] ' .. val)
  end
  api.nvim_buf_set_lines(0, 0, 100, false, display_names)
end

M.toggle = function()
  vim.bo[0].modifiable = true

  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local row_index = r - 1

  local curr_value = api.nvim_buf_get_text(0, row_index, 1, row_index, 2, {})

  local name = tests[r][1]
  if curr_value[1] == 'x' then
    tests[r] = { name, false }
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { ' ' })
  else
    tests[r] = { name, true }
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
