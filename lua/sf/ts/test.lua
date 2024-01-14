local api = vim.api
api.nvim_command('split .sf_tests')
vim.bo[0].buftype = 'nowrite'
-- vim.bo[0].buftype = 'prompt'
local win_handle = api.nvim_tabpage_get_win(0)
my_buf_handle = api.nvim_win_get_buf(0)

-- api.nvim_win_set_height(0, 30)
-- jobID = api.nvim_call_function("termopen", { "$SHELL" })
-- api.nvim_command('wincmd p') -- go back to previous window

-- events = vim.api.nvim_buf_get_keymap(0, "n")
-- kss = vim.api.nvim_buf_get_li"es(0, 0, 3, true)

api.nvim_buf_set_keymap(0, 'n', 'u', ":lua print'hello'<CR>", { noremap = true })
api.nvim_buf_set_keymap(0, 'n', 'e', ":lua vim.api.nvim_buf_delete(0, {force=true})<CR>", { noremap = true, silent = true })
vim.bo[0].modifiable = false
-- api.nvim_set_option_value('modifiable', true, { buf = 0})

-- nvim_buf_delete(0)
ss = api.nvim_buf_get_text(0, 0, 0, 0, 1, {})
winb = vim.fn.win_findbuf(my_buf_handle) -- empty table: if next(myTable) == nil then
-- nvim_buf_call/nvim_win_call
