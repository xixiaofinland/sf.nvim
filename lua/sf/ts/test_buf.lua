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

    M.set_test_names(test_names)

    api.nvim_buf_set_keymap(0, 'n', 'a', ':lua require("sf.ts.buf").update_first_char()<CR>', { noremap = true })

    -- vim.bo[0].modifiable = false
    -- else if H.is_open_already(buf_id)
  elseif win_id ~= nil and H.is_open_already(win_id) then
    api.nvim_set_current_win(win_id)
  end
end

M.set_test_names = function(test_names)
  api.nvim_buf_set_lines(0, 0, 100, false, test_names)
  -- for key, val in pairs(test_names) do
  --   print(key, val)
  --   api.nvim_buf_set_text(0, key + 1, 0, key + 1, 1, { val })
  -- end
end

M.update_first_char = function()
  vim.bo[0].modifiable = true
  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  local row = r - 1
  api.nvim_buf_set_text(0, row, 0, row, 1, { 'x' })

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
