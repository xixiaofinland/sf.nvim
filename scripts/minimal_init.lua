vim.cmd([[let &rtp.=','.getcwd()]])

if #vim.api.nvim_list_uis() == 0 then
  vim.cmd("set rtp+=deps/mini.nvim")
  require("mini.test").setup()
end

vim.cmd("set rtp+=deps/nvim-treesitter")
-- Prepended and absolute: the pinned parsers must win over any the user has
-- installed, and still resolve after a test `cd`s away from the repo root.
vim.opt.rtp:prepend(vim.fn.getcwd() .. "/deps/parsers")
