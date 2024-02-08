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

local sf_group = vim.api.nvim_create_augroup("Sf", { clear = true })

vim.api.nvim_create_autocmd({ 'FileType' }, {
  group = sf_group,
  pattern = 'apex',
  callback = function()
    vim.bo.commentstring = '//%s'
    vim.bo.fixendofline = false -- Salesforce doesn't like end of line
  end
})

vim.api.nvim_create_autocmd({ 'VimEnter' }, {
  group = sf_group,
  desc = "Run sf org cmd and store org info in the plugin",
  once = true,
  callback = function()
    require('sf.org').fetch_org_list()
  end,
})

local function set_hotkeys()
  if not vim.tbl_contains({ "apex", "sosl", "soql", "js" }, vim.bo.filetype) then
    return
  end

  -- not inside a sf project folder
  if not pcall(require('sf.util').get_sf_root) then
    return
  end

  -- Set hotkeys

  local nmap = function(keys, func, desc)
    if desc then
      desc = '[Sf] ' .. desc
    end
    vim.keymap.set('n', keys, func, { buffer = true, desc = desc })
  end

  nmap('<leader>ss', require("sf.org").set_target_org, "[s]et target_org current workspace")
  nmap('<leader>sS', require("sf.org").set_global_target_org, "[S]et global target_org")

  nmap('<leader>sf', require("sf.org").fetch_org_list, "[F]etch orgs info")

  nmap('<leader>sd', require("sf.org").diff_in_target_org, "[d]iff in target_org")
  nmap('<leader>sD', require("sf.org").select_org_to_diff_in, "[D]iff in org...")

  nmap('<leader>mr', require("sf.org").retrieve_metadata_lists, "[m]etadata [l]ist retrieve")
  nmap('<leader>ml', require("sf.org").select_md_to_retrieve, "[m]etadata [r]etrieve")
  nmap('<leader>mt', require("sf.org").retrieve_apex_under_cursor, "[m]etadata [T]his retrieve")

  nmap('<leader><leader>', require("sf.term").toggle, "[T]erminal toggle")

  nmap('<leader>s-', require("sf.term").go_to_sf_root, "CD into [R]oot")
  nmap('<C-c>', require("sf.term").cancel, "[C]ancel current running command")

  nmap('<leader>sp', require("sf.term").save_and_push, "[P]ush current file")
  nmap('<leader>sr', require("sf.term").retrieve, "[R]etrieve current file")

  nmap('<leader>ta', require("sf.term").run_all_tests_in_this_file, "[T]est [A]ll")
  nmap('<leader>tt', require("sf.term").run_current_test, "[T]est [T]his under cursor")

  nmap('<leader>to', require("sf.test").open, "[T]est [O]pen Buf Select")
  nmap('<leader>tr', require("sf.term").repeat_last_tests, "[T]est [R]epeat")
end

vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
  group = sf_group,
  callback = set_hotkeys
})
