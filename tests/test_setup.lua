local helpers = dofile('tests/helpers.lua')
local child = helpers.new_child_neovim()
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.lua([[Sf = require('sf')]])
      child.lua([[Util = require('sf.util')]])
      child.lua([[Term = require('sf.term')]])
      child.lua([[Md = require('sf.md')]])
      child.lua([[Test = require('sf.test')]])
      child.lua([[Ctags = require('sf.ctags')]])
      child.lua([[Test_sign = require('sf.sub.test_sign')]])
    end,
    post_once = child.stop,
  },
})

local cmd_returns_pattern = function(cmd, pattern) return child.cmd_capture(cmd):find(pattern) ~= nil end
local has_nmap = function(lhs, pattern) return cmd_returns_pattern('nmap ' .. lhs, pattern) end
local expect_config = function(field, value) eq(child.lua_get('vim.g.sf.' .. field), value) end

T['setup()'] = new_set()

T['setup()']['has filetypes defined'] = function()
  child.cmd('edit tests/dir/sf-project/SfProject.cls')
  eq(child.lua_get('vim.bo.filetype'), 'apex')

  child.cmd('edit tests/dir/sf-project/Account.trigger')
  eq(child.lua_get('vim.bo.filetype'), 'apex')

  child.cmd('edit tests/dir/sf-project/abc.soql')
  eq(child.lua_get('vim.bo.filetype'), 'soql')

  child.cmd('edit tests/dir/sf-project/query.sosl')
  eq(child.lua_get('vim.bo.filetype'), 'sosl')

  child.cmd('edit tests/dir/sf-project/page.html')
  eq(child.lua_get('vim.bo.filetype'), 'html')
end

T['setup()']['has default config'] = function()
  eq(child.lua_get('type(vim.g.sf)'), 'table')

  expect_config('enable_hotkeys', true)
  expect_config('fetch_org_list_at_nvim_start', true)
  expect_config('hotkeys_in_filetypes', { "apex", "sosl", "soql", "javascript", "html" })
  expect_config('types_to_retrieve', { "ApexClass", "ApexTrigger", "StaticResource", "LightningComponentBundle" })
  expect_config('term_config', {
    ft = 'SFTerm',
    blend = 10,
    dimensions = {
      height = 0.4,
      width = 0.8,
      x = 0.5,
      y = 0.9,
    },
    border = 'single',
    hl = 'Normal',
    clear_env = false,
  })
  expect_config('default_dir', '/force-app/main/default/')
  expect_config('plugin_folder_name', '/sf_cache/')
  expect_config('auto_display_code_sign', true)
  expect_config('code_sign_highlight', {
    covered = { fg = "#B7F071" },
    uncovered = { fg = "#F07178" },
  })
end

T['setup()']['has default term config'] = function()
  eq(child.lua_get('type(vim.g.sf.term_config)'), 'table')

  eq(child.lua_get('Term.get_config()'), {
    ft = 'SFTerm',
    blend = 10,
    dimensions = {
      height = 0.4,
      width = 0.8,
      x = 0.5,
      y = 0.9,
    },
    border = 'single',
    hl = 'Normal',
    clear_env = false,
  })
end

T['setup()']['can set custom config'] = function()
  child.sf_setup({ enable_hotkeys = true, hotkeys_in_filetypes = { "apex" } })

  eq(child.lua_get('vim.g.sf.enable_hotkeys'), true)
  eq(child.lua_get('vim.g.sf.hotkeys_in_filetypes'), { "apex" })
end

T['setup()']['can set custom term config'] = function()
  local custom_cfg = {
    term_config = {
      ft = 'MyTerm',
      blend = 3,
      dimensions = {
        height = 0.8,
        width = 0.5,
        x = 0.5,
        y = 0.9,
      },
      border = 'single',
      hl = 'Normal',
      clear_env = true,
    }
  }

  child.sf_setup(custom_cfg)

  eq(child.lua_get('Term.get_config()'), custom_cfg.term_config)
end

T['setup()']['has default code sign config'] = function()
  eq(child.lua_get('type(vim.g.sf.code_sign_highlight)'), 'table')

  cmd_returns_pattern('highlight SfCovered', child.lua_get('vim.g.sf.code_sign_highlight.covered.fg'))
  cmd_returns_pattern('highlight SfUncovered', child.lua_get('vim.g.sf.code_sign_highlight.uncovered.fg'))

  eq(child.lua_get('vim.tbl_isempty(vim.fn.sign_getdefined("sf_covered"))'), false)
  eq(child.lua_get('vim.tbl_isempty(vim.fn.sign_getdefined("sf_uncovered"))'), false)
end

T['setup()']['no user-keys when non-sf-project dir'] = function()
  child.cmd('edit tests/dir/non-sf-project/NonsfProject.cls')

  -- global;
  eq(has_nmap('<leader>ss', 'Sf'), false)
  eq(has_nmap('<leader>sf', 'Sf'), false)
  eq(has_nmap('<leader>so', 'Sf'), false)
  eq(has_nmap('<leader>ml', 'Sf'), false)

  -- file-level;
  eq(has_nmap('<leader>sp', 'Sf'), false)
  eq(has_nmap('<leader>sr', 'Sf'), false)
end

T['setup()']['only global user-keys when sf-project dir but file not listed in "hotkeys_in_filetypes"'] = function()
  child.cmd('edit tests/dir/sf-project/test.txt')

  -- global;
  eq(has_nmap('<leader>ss', 'Sf'), true)
  eq(has_nmap('<leader>sf', 'Sf'), true)
  eq(has_nmap('<leader>so', 'Sf'), true)
  eq(has_nmap('<leader>ml', 'Sf'), true)

  -- file-level;
  eq(has_nmap('<leader>sp', 'Sf'), false)
  eq(has_nmap('<leader>sr', 'Sf'), false)
end

T['setup()']['has all user-keys when opening Apex in sf-project dir'] = function()
  child.cmd('edit tests/dir/sf-project/SfProject.cls')

  -- global;
  eq(has_nmap('<leader>ss', 'Sf'), true)
  eq(has_nmap('<leader>sf', 'Sf'), true)
  eq(has_nmap('<leader>so', 'Sf'), true)
  eq(has_nmap('<leader>ml', 'Sf'), true)

  -- file-level;
  eq(has_nmap('<leader>sp', 'Sf'), true)
  eq(has_nmap('<leader>sr', 'Sf'), true)
end

return T
