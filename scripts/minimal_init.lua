vim.cmd([[let &rtp.=','.getcwd()]])

if #vim.api.nvim_list_uis() == 0 then
  vim.cmd('set rtp+=deps/mini.nvim')
  vim.cmd('set rtp+=deps/plenary.nvim')
  vim.cmd('set rtp+=deps/telescope.nvim')
  vim.cmd('set rtp+=deps/nvim-treesitter')

  require('mini.test').setup()
end
