local Cfg = {}

local default_cfg = {
  -- Unless you want to customize, no need to copy-paste any of these
  -- They are applied automatically

  -- This plugin has both hotkeys and user commands supplied
  -- This flag enable/disable hotkeys while user commands are always enabled
  enable_hotkeys = true,

  -- Some hotkeys are on "project level" thus always enabled. Examples: "set default org", "fetch org info".
  -- Other hotkeys are enabled when only metadata filetypes are loaded in the current buffer. Example: "push/retrieve current metadata file"
  -- This list defines what metadata filetypes have the "other hotkeys" enabled.
  -- For example, if you want to push/retrieve css files, it needs to be added into this list.
  hotkeys_in_filetypes = {
    "apex", "sosl", "soql", "javascript", "html"
  },

  -- Define what metadata to be listed in `list_md_to_retrieve()` (<leader>ml)
  -- Salesforce has numerous metadata types. We narrow down the scope of `list_md_to_retrieve()`.
  types_to_retrieve = {
    "ApexClass",
    "ApexTrigger",
    "StaticResource",
    "LightningComponentBundle"
  },

  -- Configuration for the integrated terminal
  term_config = {
    blend = 10,     -- background transparency: 0 is fully opaque; 100 is fully transparent
    dimensions = {
      height = 0.4, -- proportional of the editor height. 0.4 means 40%.
      width = 0.8,  -- proportional of the editor width. 0.8 means 80%.
      x = 0.5,      -- starting position of width. Details in `get_dimension()` in raw_term.lua source code.
      y = 0.9,      -- starting position of height. Details in `get_dimension()` in raw_term.lua source code.
    },
  },

  -- the sf project metadata folder, update this in case you diverged from the default sf folder structure
  default_dir = '/force-app/main/default/',

  -- the folder this plugin uses to store intermediate data. It's under the sf project root directory.
  plugin_folder_name = '/cache/',

  -- after the test running with code coverage completes, display uncovered line sign automatically.
  -- you can set it to `false`, then manually run toggle_sign command.
  auto_display_code_sign = true,

  -- code coverage sign icon colors
  code_sign_highlight = {
    covered = { fg = "#B7F071" }, -- set `fg = ""` to disable this sign icon
    uncovered = { fg = "#F07178" }, -- set `fg = ""` to disable this sign icon
  },
}

local apply_config = function(opt)
  Cfg.config = vim.tbl_deep_extend('force', default_cfg, opt)
end

local init = function()
  -- Define Salesforce related filetypes
  vim.filetype = on
  vim.filetype.add({
    extension = {
      cls = 'apex',
      apex = 'apex',
      trigger = 'apex',
      soql = 'soql',
      sosl = 'sosl',
      page = 'html',
    }
  })

  local sf_group = vim.api.nvim_create_augroup("SF", { clear = true })

  -- Disable "end of line" for relevant filetypes in sf project folder,
  -- Because metadata files retrieved from Salesforce don't have it
  vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = sf_group,
    pattern = { 'javascript, apex, html' },
    callback = function()
      if pcall(require('sf.util').get_sf_root) then
        -- TODO: it seems not set correctly. Check why.
        vim.bo.fixendofline = false
      end
    end
  })

  vim.api.nvim_create_autocmd({ 'FileType' }, {
    group = sf_group,
    pattern = 'apex',
    callback = function()
      vim.bo.commentstring = '//%s'
      vim.bo.fixendofline = false

      -- the code-coverage sign applies to the newly opened Apex
      local sign = require('sf.sign')
      if sign.is_enabled() then
        sign.refresh_and_place()
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

  -- Fetch org info in Vim start
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    group = sf_group,
    desc = 'Run sf org cmd and store org info in the plugin',
    once = true,
    callback = function()
      if vim.fn.executable('sf') == 1 then
        require('sf').fetch_org_list()
      end
    end,
  })

  local function set_keys()
    if not pcall(require('sf.util').get_sf_root) then
      return
    end

    local Sf = require('sf')

    -- Ex user commands

    vim.api.nvim_create_user_command("SFFetchOrgList", function()
      Sf.fetch_org_list()
    end, {})

    vim.api.nvim_create_user_command("SFSetTargetOrg", function()
      Sf.set_target_org()
    end, {})

    vim.api.nvim_create_user_command("SFDiff", function()
      Sf.diff_in_target_org()
    end, {})

    vim.api.nvim_create_user_command("SFDiffInOrg", function()
      Sf.diff_in_org()
    end, {})

    vim.api.nvim_create_user_command("SFListMdToRetrieve", function()
      Sf.list_md_to_retrieve()
    end, {})

    vim.api.nvim_create_user_command("SFPullMd", function()
      Sf.pull_md_json()
    end, {})

    vim.api.nvim_create_user_command("SFListMdTypeToRetrieve", function()
      Sf.list_md_type_to_retrieve()
    end, {})

    vim.api.nvim_create_user_command("SFPullMdType", function()
      Sf.pull_md_type_json()
    end, {})

    vim.api.nvim_create_user_command("SFCreateApexClass", function()
      Sf.create_apex_class()
    end, {})

    vim.api.nvim_create_user_command("SFCreateAuraBundle", function()
      Sf.create_aura_bundle()
    end, {})

    vim.api.nvim_create_user_command("SFCreateLwcBundle", function()
      Sf.create_lwc_bundle()
    end, {})

    vim.api.nvim_create_user_command("SFToggle", function()
      Sf.toggle_term()
    end, {})

    vim.api.nvim_create_user_command("SFSaveAndPush", function()
      Sf.save_and_push()
    end, {})

    vim.api.nvim_create_user_command("SFPushDelta", function()
      Sf.push_delta()
    end, {})

    vim.api.nvim_create_user_command("SFRetrieve", function()
      Sf.retrieve()
    end, {})

    vim.api.nvim_create_user_command("SFRetrieveDelta", function()
      Sf.retrieve_delta()
    end, {})

    vim.api.nvim_create_user_command("SFRetrievePackage", function()
      Sf.retrieve_package()
    end, {})

    vim.api.nvim_create_user_command("SFRunAnonymousApex", function()
      Sf.run_anonymous()
    end, {})

    vim.api.nvim_create_user_command("SFRunQuery", function()
      Sf.run_query()
    end, {})

    vim.api.nvim_create_user_command("SFRunToolingQuery", function()
      Sf.run_tooling_query()
    end, {})

    vim.api.nvim_create_user_command("SFCancelCommand", function()
      Sf.cancel()
    end, {})

    vim.api.nvim_create_user_command("SFRunAllTestsInThisFile", function()
      Sf.run_all_tests_in_this_file()
    end, {})

    vim.api.nvim_create_user_command("SFRunAllTestsInThisFileWithCoverage", function()
      Sf.run_all_tests_in_this_file_with_coverage()
    end, {})


    vim.api.nvim_create_user_command("SFRunCurrentTest", function()
      Sf.run_current_test()
    end, {})

    vim.api.nvim_create_user_command("SFRunCurrentTestWithCoverage", function()
      Sf.run_current_test_with_coverage()
    end, {})

    vim.api.nvim_create_user_command("SFRepeatTest", function()
      Sf.repeat_last_tests()
    end, {})

    vim.api.nvim_create_user_command("SFRunLocalTests", function()
      Sf.run_local_tests()
    end, {})

    vim.api.nvim_create_user_command("SFOpenTestSelect", function()
      Sf.open_test_select()
    end, {})

    vim.api.nvim_create_user_command("SFCreateCtags", function()
      Sf.create_ctags()
    end, {})

    if not Cfg.config.enable_hotkeys then
      return
    end

    -- Set hotkeys

    local nmap = function(keys, func, desc)
      if desc then
        desc = desc .. ' [Sf]'
      end
      vim.keymap.set('n', keys, func, { buffer = true, desc = desc })
    end

    -- Common hotkeys for all files;
    nmap('<leader>ss', Sf.set_target_org, "set target_org current workspace")
    nmap('<leader>sS', Sf.set_global_target_org, "set global target_org")
    nmap('<leader>sf', Sf.fetch_org_list, "fetch orgs info")
    nmap('<leader>ml', Sf.list_md_to_retrieve, "metadata listing")
    nmap('<leader>mtl', Sf.list_md_type_to_retrieve, "metadata-type listing")
    nmap('<leader><leader>', Sf.toggle_term, "terminal toggle")
    nmap('<C-c>', Sf.cancel, "cancel running command")
    nmap('<leader>s-', Sf.go_to_sf_root, "cd into root")
    nmap('<leader>ct', Sf.create_ctags, 'create ctag file in project root')
    nmap('<leader>ft', Sf.create_and_list_ctags, 'fzf list updated ctags')

    -- Hotkeys for metadata files only;
    if vim.tbl_contains(Cfg.config.hotkeys_in_filetypes, vim.bo.filetype) then
      nmap('<leader>sd', Sf.diff_in_target_org, "diff in target_org")
      nmap('<leader>sD', Sf.diff_in_org, "diff in org...")
      nmap('<leader>ma', Sf.retrieve_apex_under_cursor, "apex under cursor retrieve")
      nmap('<leader>sp', Sf.save_and_push, "push current file")
      nmap('<leader>sr', Sf.retrieve, "retrieve current file")

      vim.keymap.set('x', '<leader>sq', Sf.run_highlighted_soql, { buffer = true, desc = "SOQL run highlighted text" })

      nmap('<leader>ta', Sf.run_all_tests_in_this_file, "test all in this file")
      nmap('<leader>tA', Sf.run_all_tests_in_this_file_with_coverage, "test all with coverage info")
      nmap('<leader>tt', Sf.run_current_test, "test this under cursor")
      nmap('<leader>tT', Sf.run_current_test_with_coverage, "test this under cursor with coverage info")
      nmap('<leader>to', Sf.open_test_select, "open test select buf")
      nmap('\\s', Sf.toggle_sign, "toggle signs for code coverage")
      nmap('<leader>tr', Sf.repeat_last_tests, "repeat last test")
      nmap('<leader>cc', Sf.copy_apex_name, "copy apex name")
      nmap('<leader>cc', Sf.copy_apex_name, "copy apex name")
      nmap('[v', Sf.uncovered_jump_backward, "jump to previous uncovered sign icon line")
      nmap(']v', Sf.uncovered_jump_forward, "jump to next uncovered sign icon line")
    end
  end

  -- Set hotkeys and user commands
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'FileType' }, {
    group = sf_group,
    callback = set_keys
  })

  -- Initiate the raw term
  require('sf.term').setup(Cfg.config.term_config)

  require('sf.sign').setup()
end

Cfg.setup = function(opt)
  opt = opt or {}
  vim.validate({ config = { opt, 'table', true } })
  apply_config(opt)

  init()
end

return Cfg
