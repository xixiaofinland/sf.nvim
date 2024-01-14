local T = require('sf.ts.ts')
local M = {}
local H = {}
local api = vim.api
local buf_name = '.sf_tests'
local buf_id = nil
local win_id = nil
local tests_to_run = {}

M.open = function()
  if T.get_test_class_name == nil then
    return vim.notify('not in Apex test file', vim.log.levels.ERROR)
  end

  local test_names = T.get_test_method_names_in_curr_file()

  if next(test_names) == nil then
    return vim.notify('no Apex test found', vim.log.levels.ERROR)
  end

  if buf_id == nil then
    api.nvim_command('split ' .. buf_name)
    buf_id = api.nvim_win_get_buf(0)
    win_id = api.nvim_tabpage_get_win(0)

    tests_to_run = {}
    M.set_test_names(test_names)
    api.nvim_buf_set_keymap(0, 'n', 't', ':lua require("sf.ts.test_buf").toggle()<CR>', { noremap = true })

    vim.bo[0].modifiable = false

    -- else if H.is_open_already(buf_id)
  elseif win_id ~= nil and H.is_open_already(win_id) then
    api.nvim_set_current_win(win_id)
  end
end

M.set_test_names = function(test_names)
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

  local cur_value = api.nvim_buf_get_text(0, row_index, 1, row_index, 2, {})

  if cur_value[1] == 'x' then
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { ' ' })
  else
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { 'x' })
  end

  vim.bo[0].modifiable = false
end

------------- helper -----------------------

H.is_open_already = function(id)
  local win_num = vim.fn.win_findbuf(id)
  if win_num == nil then
    return false
  end
  return true
end

return M
