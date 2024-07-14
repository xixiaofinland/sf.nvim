local T = require('sf.term')
local TS = require('sf.ts')
local U = require('sf.util')
local C = require('sf.config')

local P = {}
local Test = {}

Test.open = function()
  P.open()
end

Test.run_current_test_with_coverage = function()
  Test.run_current_test('-c ')
end

Test.run_current_test = function(extraParams)
  extraParams = extraParams or ''

  local test_class_name = TS.get_test_class_name()
  if U.isempty(test_class_name) then
    return U.show_warn('Not in a test class.')
  end
  local test_name = TS.get_current_test_method_name()
  if U.isempty(test_name) then
    return U.show_warn('Cursor not in a test method.')
  end

  local cmd = string.format("sf apex run test --tests %s.%s -r human -w 5 %s-o %s", test_class_name, test_name,
    extraParams, U.get())
  U.last_tests = cmd
  T.run(cmd)
end

Test.run_all_tests_in_this_file_with_coverage = function()
  Test.run_all_tests_in_this_file('-c ')
end

Test.run_all_tests_in_this_file = function(extraParams)
  extraParams = extraParams or ''

  local test_class_name = TS.get_test_class_name()
  if U.isempty(test_class_name) then
    return U.show_warn('Not in a test class.')
  end

  local cmd = string.format("sf apex run test --class-names %s -r human -w 5 %s-o %s", test_class_name, extraParams,
    U.get())
  U.last_tests = cmd
  T.run(cmd)
end

Test.repeat_last_tests = function()
  if U.isempty(U.last_tests) then
    return U.show_warn('Last test command is empty.')
  end

  T.run(U.last_tests)
end

Test.run_local_tests = function()
  local cmd = string.format("sf apex run test --test-level RunLocalTests --code-coverage -r human --wait 180 -o %s",
    U.get())
  U.last_tests = cmd
  T.run(cmd)
end

Test.save_test_coverage_locally = function()
  U.create_cache_folder_if_not_exist()

  local name = "test_result.json"
  local cache_folder = U.get_cache_path()
  local cmd = 'sf apex get test -i 7071n0000Buux9s -c --json > ' .. cache_folder .. name
  U.silent_job_call(cmd, "Code coverage saved.", "Code coverage save failed!")
end

-- prompt below

local api = vim.api
local buftype = 'nowrite'
local filetype = 'sf_test_prompt'

P.buf = nil
P.win = nil
P.class = nil
P.tests = nil
P.test_num = nil
P.selected_tests = {}

P.open = function()
  local class = TS.get_test_class_name()
  if U.isempty(class) then
    U.show('Not an Apex test class.')
  end

  local test_names = TS.get_test_method_names_in_curr_file()
  if vim.tbl_isempty(test_names) then
    U.show('no Apex test found.')
  end

  local tests = {}
  local test_num = 0
  for _, name in ipairs(test_names) do
    table.insert(tests, name)
    test_num = test_num + 1
  end

  P.class = class
  P.tests = tests
  P.test_num = test_num

  local buf = P.use_existing_or_create_buf()
  local win = P.use_existing_or_create_win()
  P.buf = buf
  P.win = win

  api.nvim_win_set_buf(win, buf)

  P.set_keys()

  vim.bo[buf].modifiable = true
  P.display()
  vim.bo[buf].modifiable = false
end

P.set_keys = function()
  vim.keymap.set('n', 'x', function()
    P.toggle()
  end, { buffer = true, noremap = true })

  vim.keymap.set('n', 'cc', function()
    local cmd = P.build_tests_cmd(U.cmd_params) .. ' -o ' .. U.get()
    P.close()
    T.run(cmd)
    U.last_tests = cmd
    P.selected_tests = {}
  end, { buffer = true, noremap = true })

  vim.keymap.set('n', 'CC', function()
    local cmd = P.build_tests_cmd(U.cmd_coverage_params) .. ' -o ' .. U.get()
    P.close()
    T.run(cmd)
    U.last_tests = cmd
    P.selected_tests = {}
  end, { buffer = true, noremap = true })
end

P.display = function()
  api.nvim_set_current_win(P.win)
  local names = {}
  table.insert(names,
    '** "x": toggle tests; "cc": run tests; "CC": run tests with code coverage.')

  for _, test in ipairs(P.tests) do
    local class_test = string.format('%s.%s', P.class, test)
    if vim.tbl_contains(P.selected_tests, class_test) then
      table.insert(names, '[x] ' .. test)
    else
      table.insert(names, '[ ] ' .. test)
    end
  end
  api.nvim_buf_set_lines(P.buf, 0, 100, false, names)
end

P.use_existing_or_create_buf = function()
  if P.buf and api.nvim_buf_is_loaded(P.buf) then
    return P.buf
  end

  local buf = api.nvim_create_buf(false, false)
  vim.bo[buf].buftype = buftype
  vim.bo[buf].filetype = filetype

  return buf
end

P.use_existing_or_create_win = function()
  local win_hight = P.test_num + 2

  if P.win and api.nvim_win_is_valid(P.win) then
    api.nvim_set_current_win(P.win)
    api.nvim_win_set_height(P.win, win_hight)
    return P.win
  end

  api.nvim_command(win_hight .. 'split')

  return api.nvim_get_current_win()
end

P.toggle = function()
  if vim.bo[0].filetype ~= filetype then
    return U.show_err('file-type must be: ' .. filetype)
  end

  vim.bo[0].modifiable = true

  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  if r == 1 then -- 1st row is title
    return
  end

  local row_index = r - 1

  local curr_value = api.nvim_buf_get_text(0, row_index, 1, row_index, 2, {})

  local name = P.tests[row_index]
  local class_test = string.format('%s.%s', P.class, name)
  local index = U.list_find(P.selected_tests, class_test)

  if curr_value[1] == 'x' then
    if index ~= nil then
      table.remove(P.selected_tests, index)
    end
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { ' ' })
  elseif curr_value[1] == ' ' then
    if index == nil then
      table.insert(P.selected_tests, class_test)
    end
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { 'x' })
  end

  U.show('Selected: ' .. vim.tbl_count(P.selected_tests))

  vim.bo[0].modifiable = false
end

P.build_tests_cmd = function(param_str)
  if vim.tbl_isempty(P.selected_tests) then
    return U.show_err('No test is selected.')
  end

  local t = ''
  for _, test in ipairs(P.selected_tests) do
    t = string.format('%s -t %s', t, test)
  end

  local cmd = string.format('sf apex run test%s %s', t, param_str)
  return cmd
end

P.close = function()
  if P.win and api.nvim_win_is_valid(P.win) then
    api.nvim_win_close(P.win, false)
  end
end

return Test
