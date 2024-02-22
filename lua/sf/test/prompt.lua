local S = require('sf')
local U = require('sf.util')
local T = require('sf.term')
local TS = require('sf.ts')
local api = vim.api
local buftype = 'nowrite'
local filetype = 'sf_test_prompt'

local Prompt = {}

function Prompt:new()
  self.__index = self
  local newObj = {
    buf = nil,
    win = nil,
    class = nil,
    tests = nil,
    test_num = nil,
    selected_tests = {},
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
  for _, name in ipairs(test_names) do
    table.insert(tests, name)
    test_num = test_num + 1
  end

  self.class = class
  self.tests = tests
  self.test_num = test_num

  local buf = self:use_existing_or_create_buf()
  local win = self:use_existing_or_create_win()
  self.buf = buf
  self.win = win

  api.nvim_win_set_buf(win, buf)

  vim.keymap.set('n', 'x', function()
    self:toggle()
  end, { buffer = true, noremap = true })

  vim.keymap.set('n', 'cc', function()
    local cmd = self:build_selected_tests_cmd() .. ' -o ' .. S.get()
    self:close()
    T.run(cmd)
    S.last_tests = cmd
    self.selected_tests = {}
  end, { buffer = true, noremap = true })

  vim.bo[buf].modifiable = true
  self:display()
  vim.bo[buf].modifiable = false
end

function Prompt:display()
  api.nvim_set_current_win(self.win)
  local names = {}
  table.insert(names, '** Hit "x" -> toggle tests; "cc" -> run selected tests')

  for _, test in ipairs(self.tests) do
    local class_test = string.format('%s.%s', self.class, test)
    if vim.tbl_contains(self.selected_tests, class_test) then
      table.insert(names, '[x] ' .. test)
    else
      table.insert(names, '[ ] ' .. test)
    end
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
    return vim.notify('file-type must be: ' .. filetype, vim.log.levels.ERROR)
  end

  vim.bo[0].modifiable = true

  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  if r == 1 then -- 1st row is title
    return
  end

  local row_index = r - 1

  local curr_value = api.nvim_buf_get_text(0, row_index, 1, row_index, 2, {})

  local name = self.tests[row_index]
  local class_test = string.format('%s.%s', self.class, name)
  local index = U.list_find(self.selected_tests, class_test)

  if curr_value[1] == 'x' then
    if index ~= nil then
      table.remove(self.selected_tests, index)
    end
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { ' ' })
  elseif curr_value[1] == ' ' then
      if index == nil then
        table.insert(self.selected_tests, class_test)
      end
      api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { 'x' })
  end

  print(vim.inspect(self.selected_tests))

  vim.bo[0].modifiable = false
end

function Prompt:build_selected_tests_cmd()
  if next(self.selected_tests) == nil then
    return vim.notify('no selected test.', vim.log.levels.ERROR)
  end

  local t = ''
  for _, test in ipairs(self.selected_tests) do
    t = string.format('%s -t %s', t, test)
  end

  local cmd = string.format('sf apex run test%s %s', t, U.cmd_human_params)
  return cmd
end

function Prompt:close()
  if self.win and api.nvim_win_is_valid(self.win) then
    api.nvim_win_close(self.win, false)
  end
end

return Prompt
