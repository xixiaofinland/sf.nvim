vim.cmd([[let &rtp.=','.getcwd()]])

-- Where the default log isn't writable (issue-loop's sandbox), Neovim warns
-- through vim.notify, which lands among the notifications tests assert on.
-- Child Neovims inherit both from the test runner, which exports the
-- unwritable path it wanted in __NVIM_LOG_FILE_WANT and warns again from it.
vim.env.NVIM_LOG_FILE = vim.fn.tempname() .. "-nvim.log"
vim.env.__NVIM_LOG_FILE_WANT = nil

if #vim.api.nvim_list_uis() == 0 then
  vim.cmd("set rtp+=deps/mini.nvim")
  require("mini.test").setup()
end

vim.cmd("set rtp+=deps/nvim-treesitter")
-- Prepended and absolute: the pinned parsers must win over any the user has
-- installed, and still resolve after a test `cd`s away from the repo root.
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/deps/parsers")
