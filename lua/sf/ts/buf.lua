local M = {}
local H = {}
local api = vim.api
local buf_name = '.sf_tests'
local buf_id = nil
local win_id = nil
local tests_to_run = {}

M.open = function()
  if not buf_id then
    api.nvim_command('split ' .. buf_name)
    buf_id = api.nvim_win_get_buf(0)
    win_id = api.nvim_tabpage_get_win(0)

    api.nvim_buf_set_keymap(0, 'n', 'a', ':lua require("sf.ts.buf").update_first_char()<CR>', { noremap = true })


    -- vim.bo[0].modifiable = false

    -- else if H.is_open_already(buf_id)
  end
end

M.update_first_char = function()
  vim.bo[0].modifiable = true
  local r,_ = unpack(vim.api.nvim_win_get_cursor(0))
  local row = r - 1
  api.nvim_buf_set_text(0, row, 0, row, 1, {'x'})

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
