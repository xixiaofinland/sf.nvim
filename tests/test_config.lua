local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.lua([[Term = require('sf.term')]])
    end,
    post_once = child.stop,
  },
})

local has_cmd_pattern = function(cmd, pattern)
  return expect.match(child.cmd_capture(cmd), pattern)
end
local has_nmap = function(lhs)
  return has_cmd_pattern("nmap " .. lhs, "Sf")
end

local no_cmd_pattern = function(cmd, pattern)
  return expect.no_match(child.cmd_capture(cmd), pattern)
end
local no_nmap = function(lhs)
  return no_cmd_pattern("nmap " .. lhs, "Sf")
end

local expect_config = function(field, value)
  eq(child.lua_get("vim.g.sf." .. field), value)
end

T["setup()"] = new_set()

T["setup()"]["has filetypes defined"] = function()
  child.open_in_sf_dir("SfProject.cls")
  eq(child.lua_get("vim.bo.filetype"), "apex")

  child.open_in_sf_dir("Account.trigger")
  eq(child.lua_get("vim.bo.filetype"), "apex")

  child.open_in_sf_dir("abc.soql")
  eq(child.lua_get("vim.bo.filetype"), "soql")

  child.open_in_sf_dir("query.sosl")
  eq(child.lua_get("vim.bo.filetype"), "sosl")

  child.open_in_sf_dir("page.html")
  eq(child.lua_get("vim.bo.filetype"), "html")
end

T["setup()"]["has default config"] = function()
  eq(child.lua_get("type(vim.g.sf)"), "table")

  expect_config("enable_hotkeys", false)
  expect_config("fetch_org_list_at_nvim_start", true)
  expect_config("hotkeys_in_filetypes", { "apex", "sosl", "soql", "javascript", "html" })
  expect_config("types_to_retrieve", { "ApexClass", "ApexTrigger", "StaticResource", "LightningComponentBundle" })
  expect_config("term_config", {
    ft = "SFTerm",
    blend = 10,
    dimensions = {
      height = 0.4,
      width = 0.8,
      x = 0.5,
      y = 0.9,
    },
    border = "single",
    hl = "Normal",
    clear_env = false,
  })
  expect_config("terminal", "integrated")
  expect_config("default_dir", "/force-app/main/default/")
  expect_config("plugin_folder_name", "/sf_cache/")
  expect_config("auto_display_code_sign", true)
  expect_config("code_sign_highlight", {
    covered = { fg = "#b7f071" },
    uncovered = { fg = "#f07178" },
  })
end

T["setup()"]["has default term config"] = function()
  eq(child.lua_get("type(vim.g.sf.term_config)"), "table")

  eq(child.lua_get("Term.get_config()"), {
    ft = "SFTerm",
    blend = 10,
    dimensions = {
      height = 0.4,
      width = 0.8,
      x = 0.5,
      y = 0.9,
    },
    border = "single",
    hl = "Normal",
    clear_env = false,
  })
end

T["setup()"]["can set custom config"] = function()
  child.sf_setup({ enable_hotkeys = true, hotkeys_in_filetypes = { "apex" } })

  eq(child.lua_get("vim.g.sf.enable_hotkeys"), true)
  eq(child.lua_get("vim.g.sf.hotkeys_in_filetypes"), { "apex" })
end

T["setup()"]["can set custom term config"] = function()
  local custom_cfg = {
    term_config = {
      ft = "MyTerm",
      blend = 3,
      dimensions = {
        height = 0.8,
        width = 0.5,
        x = 0.5,
        y = 0.9,
      },
      border = "single",
      hl = "Normal",
      clear_env = true,
    },
  }

  child.sf_setup(custom_cfg)

  eq(child.lua_get("Term.get_config()"), custom_cfg.term_config)
end

T["setup()"]["has default code sign config"] = function()
  eq(child.lua_get("type(vim.g.sf.code_sign_highlight)"), "table")

  has_cmd_pattern("highlight SfCovered", child.lua_get("vim.g.sf.code_sign_highlight.covered.fg"))
  has_cmd_pattern("highlight SfUncovered", child.lua_get("vim.g.sf.code_sign_highlight.uncovered.fg"))

  eq(vim.tbl_isempty(child.fn.sign_getdefined("sf_covered")), false)
  eq(vim.tbl_isempty(child.fn.sign_getdefined("sf_uncovered")), false)
end

T["setup()"]["no user-keys by default"] = function()
  child.open_in_sf_dir("test.txt")

  -- global;
  no_nmap("<leader>ss")
  no_nmap("<leader>sf")
  no_nmap("<leader>so")
  no_nmap("<leader>ml")

  -- file-level;
  no_nmap("<leader>sp")
  no_nmap("<leader>sr")
end

T["setup()"]["no user-keys when non-sf-project dir"] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_non_sf_dir("NonsfProject.cls")

  -- global;
  no_nmap("<leader>ss")
  no_nmap("<leader>sf")
  no_nmap("<leader>so")
  no_nmap("<leader>ml")

  -- file-level;
  no_nmap("<leader>sp")
  no_nmap("<leader>sr")
end

T["setup()"]['only global user-keys when 1. in sf-project dir 2. opened file not in "hotkeys_in_filetypes"'] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_sf_dir("test.txt")

  -- global;
  has_nmap("<leader>ss")
  has_nmap("<leader>sf")
  has_nmap("<leader>so")
  has_nmap("<leader>ml")

  -- file-level;
  no_nmap("<leader>sp")
  no_nmap("<leader>sr")
end

T["setup()"]['only global user-keys when 0. enable_hotkeys 1. in sf-project sub-dir 2. opened file not in "hotkeys_in_filetypes"'] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.go_to_sf_sub_dir()

  -- global;
  has_nmap("<leader>ss")
  has_nmap("<leader>sf")
  has_nmap("<leader>so")
  has_nmap("<leader>ml")

  -- file-level;
  no_nmap("<leader>sp")
  no_nmap("<leader>sr")
end

T["setup()"]['has all user-keys when 0. enable_hotkeys 1. in sf-project sub-dir 2. opened file in "hotkeys_in_filetypes"'] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_sf_dir("SfProject.cls")

  -- global;
  has_nmap("<leader>ss")
  has_nmap("<leader>sf")
  has_nmap("<leader>so")
  has_nmap("<leader>ml")

  -- file-level;
  has_nmap("<leader>sp")
  has_nmap("<leader>sr")
end

T["setup()"]["global user-keys disabled -> enabled when 0. enable_hotkeys 1. switching files from non-sf-project to sf-project folder"] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_non_sf_dir("test.txt")

  no_nmap("<leader>ss")
  no_nmap("<leader>sf")
  no_nmap("<leader>so")
  no_nmap("<leader>ml")

  child.open_in_sf_dir("SfProject.cls")
  has_nmap("<leader>ss")
  has_nmap("<leader>sf")
  has_nmap("<leader>so")
  has_nmap("<leader>ml")
end

T["setup()"]["global user-keys disabled -> enabled when 0. enable_hotkeys 1. switching path from non-sf-project to sf-project folder"] = function()
  child.sf_setup({ enable_hotkeys = true })
  local root_path = child.fn.getcwd()
  child.go_to_non_sf_dir()

  no_nmap("<leader>ss")
  no_nmap("<leader>sf")
  no_nmap("<leader>so")
  no_nmap("<leader>ml")

  child.cmd("cd " .. root_path .. "/tests/dir/sf-project/sf_cache/")
  has_nmap("<leader>ss")
  has_nmap("<leader>sf")
  has_nmap("<leader>so")
  has_nmap("<leader>ml")
end

T["setup()"]["SFTerm filetype has its user-keys always defined by autocmd despite of non-sf-project dir."] = function()
  child.open_in_non_sf_dir("SFTerm")
  no_nmap("<leader><leader>")
  no_nmap("<C-c>")

  child.cmd("setfiletype SFTerm")
  has_nmap("<leader><leader>")
  has_nmap("<C-c>")
end

T["setup()"]["default has a VimEnter event defined"] = function()
  eq(#child.api.nvim_get_autocmds({ event = "VimEnter", group = "SF" }), 1)
end

T["setup()"]["the VimEnter event can be disabled by custom config"] = function()
  child.sf_setup({ fetch_org_list_at_nvim_start = false })

  eq(#child.api.nvim_get_autocmds({ event = "VimEnter", group = "SF" }), 0)
end

T["setup()"]["no user commands in non-sf-project dir"] = function()
  child.open_in_non_sf_dir("test.txt")

  eq(child.api.nvim_get_commands({})["SF"], nil)
end

T["setup()"]["has user commands in sf-project dir"] = function()
  child.open_in_sf_dir("text.txt")

  eq(child.api.nvim_get_commands({})["SF"].name, "SF")
end

return T
