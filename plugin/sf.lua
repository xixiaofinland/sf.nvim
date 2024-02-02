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

local augroup = vim.api.nvim_create_augroup("Sf", { clear = true })

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  group = augroup,
  desc = "Run sf org cmd and store org info in the plugin",
  once = true,
  callback = function()
    require('sf.org').fetch_org_list()
  end,
})
