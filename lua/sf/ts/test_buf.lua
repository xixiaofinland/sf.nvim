local TS = require('sf.ts.ts')
local M = {}
local H = {}
local api = vim.api
local buf_name = '.sf_tests'
local buf_id = nil
local win_id = nil
local test_class_name = nil
local tests = {}

M.open = function()
  test_class_name = TS.get_test_class_name()
  if test_class_name == nil then
    return vim.notify('not in Apex test file', vim.log.levels.ERROR)
  end

  local test_names = TS.get_test_method_names_in_curr_file()
  if next(test_names) == nil then
    return vim.notify('no Apex test found', vim.log.levels.ERROR)
  end

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

  local cmd = 'sf apex run test ' .. t .. "--result-format human -y "
  return cmd
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

return M
