local TS = require('sf.ts')
local api = vim.api
local buftype = 'nowrite'
local filetype = 'sf_test_prompt'

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
    test_num = nil,
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
  local test_num = 0
  for _, name in pairs(test_names) do
    table.insert(tests, { name, false })
    test_num = test_num + 1
  end

  self.test_num = test_num
  self.class = class
  self.tests = tests

  local buf = self:use_existing_or_create_buf()
  local win = self:use_existing_or_create_win()
  self.buf = buf
  self.win = win

  api.nvim_win_set_buf(win, buf)
  api.nvim_buf_set_keymap(buf, 'n', 'x', ':lua require("sf.test").toggle()<CR>', { noremap = true })
  api.nvim_buf_set_keymap(buf, 'n', 'cc', ':lua require("sf.test").run_selected()<CR>', { noremap = true })

  vim.bo[buf].modifiable = true
  self:display_test_names()
  vim.bo[buf].modifiable = false
end

function Prompt:display_test_names()
  api.nvim_set_current_win(self.win)
  local names = {}
  table.insert(names, '** Hit "x" -> toggle tests; "cc" -> execute in terminal')

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

  local split_win_rows = self.test_num + 2
  api.nvim_command(split_win_rows .. 'split')

  return api.nvim_get_current_win()
end

function Prompt:toggle()
  if vim.bo[0].filetype ~= filetype then
    return vim.notify('not supposed to be used in this filetype', vim.log.levels.ERROR)
  end

  vim.bo[0].modifiable = true

  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  -- 1st row is title
  if r == 1 then
    return
  end

  local row_index = r - 1

  local curr_toggle_value = api.nvim_buf_get_text(0, row_index, 1, row_index, 2, {})

  local name = self.tests[row_index][1]
  if curr_toggle_value[1] == 'x' then
    self.tests[row_index] = { name, false }
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { ' ' })
  else
    if curr_toggle_value[1] == ' ' then
      self.tests[row_index] = { name, true }
      api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { 'x' })
    end
  end

  vim.bo[0].modifiable = false
end

function Prompt:get_selected_tests()
  local selected = {}
  for _, v in pairs(self.tests) do
    if v[2] then
      table.insert(selected, v[1])
    end
  end
  return selected
end

function Prompt:build_selected_tests_cmd()
  if self.class == nil or next(self.tests) == nil then
    return vim.notify('no test class name or tests', vim.log.levels.ERROR)
  end

  local t = ''
  local selected = self:get_selected_tests()
  for _, test in pairs(selected) do
    t = t .. '-t ' .. self.class .. '.' .. test .. ' '
  end

  local cmd = 'sf apex run test ' .. t .. "--result-format human -y"
  return cmd
end

function Prompt:close()
  if self.win and api.nvim_win_is_valid(self.win) then
    api.nvim_win_close(self.win, false)
  end
end

return Prompt
