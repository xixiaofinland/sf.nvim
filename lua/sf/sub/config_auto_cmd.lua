local M = {}

M.set_auto_cmd_and_try_set_default_keys = function()
  local sf_group = vim.api.nvim_create_augroup("SF", { clear = true })

  -- Disable "end of line" for relevant filetypes in sf project folder,
  -- Because metadata files retrieved from Salesforce don't have it
  vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = sf_group,
    pattern = { 'javascript, apex, html' },
    callback = function()
      if pcall(require('sf.util').get_sf_root) then
        vim.bo.fixendofline = false -- TODO: it seems not set correctly. Check why.
      end
    end
  })

  vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = sf_group,
    pattern = 'apex',
    callback = function()
      vim.bo.commentstring = '//%s'
      vim.bo.fixendofline = false

      -- try refresh code coverage signs in the new opened Apex file
      local t = require('sf.test')
      if t.is_sign_enabled() then
        t.refresh_and_place_sign()
      end
    end
  })

  -- Set hotkeys for the integrated terminal
  vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = sf_group,
    pattern = 'SFTerm',
    callback = function()
      local nmap = function(keys, func, desc)
        if desc then
          desc = desc .. ' [Sf]'
        end
        vim.keymap.set('n', keys, func, { buffer = true, desc = desc })
      end

      nmap('<leader><leader>', require('sf').toggle_term, 'terminal toggle')
      nmap('<C-c>', require('sf').cancel, 'cancel running command')
    end
  })

  -- Refresh test code coverage info for the current Apex file
  vim.api.nvim_create_autocmd("BufEnter", {
    group = sf_group,
    pattern = { "*.cls" },
    callback = function()
      local ok, content = pcall(require('sf').refresh_current_file_covered_percent)
      if not ok then
        -- swallow error and be silent
      end
    end
  })

  -- Fetch org info in Vim start
  if vim.g.sf.fetch_org_list_at_nvim_start then
    vim.api.nvim_create_autocmd({ 'VimEnter' }, {
      group = sf_group,
      desc = 'Run sf org cmd and store org info in the plugin',
      callback = function()
        if vim.fn.executable('sf') == 1 then
          require('sf').fetch_org_list()
        end
      end,
    })
  end

  local function try_set_keys_and_user_commands()
    if not pcall(require('sf.util').get_sf_root) then
      return
    end

    require('sf.sub.config_user_command').create_user_commands()

    if not vim.g.sf.enable_hotkeys then
      return
    end

    require('sf.sub.config_user_key').set_default_hotkeys()
  end

  -- Set hotkeys and user commands
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
    group = sf_group,
    callback = try_set_keys_and_user_commands
  })
end

return M
