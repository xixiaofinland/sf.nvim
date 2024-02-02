vim.filetype = on
vim.filetype.add({
  extension = {
    cls = 'apex',
    apex = 'apex',
    trigger = 'apex',
    soql = 'soql',
    sosl = 'sosl',
  }
})

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  callback = function()
    require('sf.org').fetch_org_list()
  end,
})
