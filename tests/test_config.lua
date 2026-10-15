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

T["setup()"]["sets fixendofline=false for javascript files in sf project"] = function()
  child.open_in_sf_dir("hello.js")
  eq(child.lua_get("vim.bo.filetype"), "javascript")
  eq(child.lua_get("vim.bo.fixendofline"), false)
end

T["setup()"]["sets fixendofline=false for html files in sf project"] = function()
  child.open_in_sf_dir("page.html")
  eq(child.lua_get("vim.bo.filetype"), "html")
  eq(child.lua_get("vim.bo.fixendofline"), false)
end

T["setup()"]["has default config"] = function()
  eq(child.lua_get("type(vim.g.sf)"), "table")

  child.expect_config("enable_hotkeys", false)
  child.expect_config("fetch_org_list_at_nvim_start", true)
  child.expect_config("hotkeys_in_filetypes", { "apex", "sosl", "soql", "javascript", "html" })
  child.expect_config("types_to_retrieve", { "ApexClass", "ApexTrigger", "StaticResource", "LightningComponentBundle" })
  child.expect_config("term_config", {
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
  child.expect_config("terminal", "integrated")
  child.expect_config("default_dir", "/force-app/main/default/")
  child.expect_config("plugin_folder_name", "/sf_cache/")
  child.expect_config("auto_display_code_sign", true)
  child.expect_config("code_sign_highlight", {
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

  child.has_cmd_pattern("highlight SfCovered", child.lua_get("vim.g.sf.code_sign_highlight.covered.fg"))
  child.has_cmd_pattern("highlight SfUncovered", child.lua_get("vim.g.sf.code_sign_highlight.uncovered.fg"))

  eq(vim.tbl_isempty(child.fn.sign_getdefined("sf_covered")), false)
  eq(vim.tbl_isempty(child.fn.sign_getdefined("sf_uncovered")), false)
end

T["setup()"]["no user-keys by default"] = function()
  child.open_in_sf_dir("test.txt")

  -- global;
  child.no_nmap("<leader>ss")
  child.no_nmap("<leader>sf")
  child.no_nmap("<leader>so")
  child.no_nmap("<leader>ml")

  -- file-level;
  child.no_nmap("<leader>sp")
  child.no_nmap("<leader>sr")
end

T["setup()"]["no user-keys when non-sf-project dir"] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_non_sf_dir("NonSfProject.cls")

  -- global;
  child.no_nmap("<leader>ss")
  child.no_nmap("<leader>sf")
  child.no_nmap("<leader>so")
  child.no_nmap("<leader>ml")

  -- file-level;
  child.no_nmap("<leader>sp")
  child.no_nmap("<leader>sr")
end

T["setup()"]['only global user-keys when 1. in sf-project dir 2. opened file not in "hotkeys_in_filetypes"'] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_sf_dir("test.txt")

  -- global;
  child.has_nmap("<leader>ss")
  child.has_nmap("<leader>sf")
  child.has_nmap("<leader>so")
  child.has_nmap("<leader>ml")

  -- file-level;
  child.no_nmap("<leader>sp")
  child.no_nmap("<leader>sr")
end

T["setup()"]['only global user-keys when 0. enable_hotkeys 1. in sf-project sub-dir 2. opened file not in "hotkeys_in_filetypes"'] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.go_to_sf_sub_dir()

  -- global;
  child.has_nmap("<leader>ss")
  child.has_nmap("<leader>sf")
  child.has_nmap("<leader>so")
  child.has_nmap("<leader>ml")

  -- file-level;
  child.no_nmap("<leader>sp")
  child.no_nmap("<leader>sr")
end

T["setup()"]['has all user-keys when 0. enable_hotkeys 1. in sf-project sub-dir 2. opened file in "hotkeys_in_filetypes"'] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_sf_dir("SfProject.cls")

  -- global;
  child.has_nmap("<leader>ss")
  child.has_nmap("<leader>sf")
  child.has_nmap("<leader>so")
  child.has_nmap("<leader>ml")

  -- file-level;
  child.has_nmap("<leader>sp")
  child.has_nmap("<leader>sr")
end

T["setup()"]["global user-keys disabled -> enabled when 0. enable_hotkeys 1. switching files from non-sf-project to sf-project folder"] = function()
  child.sf_setup({ enable_hotkeys = true })
  child.open_in_non_sf_dir("test.txt")

  child.no_nmap("<leader>ss")
  child.no_nmap("<leader>sf")
  child.no_nmap("<leader>so")
  child.no_nmap("<leader>ml")

  child.open_in_sf_dir("SfProject.cls")
  child.has_nmap("<leader>ss")
  child.has_nmap("<leader>sf")
  child.has_nmap("<leader>so")
  child.has_nmap("<leader>ml")
end

T["setup()"]["global user-keys disabled -> enabled when 0. enable_hotkeys 1. switching path from non-sf-project to sf-project folder"] = function()
  child.sf_setup({ enable_hotkeys = true })
  local root_path = child.fn.getcwd()
  child.go_to_non_sf_dir()

  child.no_nmap("<leader>ss")
  child.no_nmap("<leader>sf")
  child.no_nmap("<leader>so")
  child.no_nmap("<leader>ml")

  child.cmd("cd " .. root_path .. "/tests/dir/sf-project/sf_cache/")
  child.has_nmap("<leader>ss")
  child.has_nmap("<leader>sf")
  child.has_nmap("<leader>so")
  child.has_nmap("<leader>ml")
end

T["setup()"]["SFTerm filetype has its user-keys always defined by autocmd despite of non-sf-project dir."] = function()
  child.open_in_non_sf_dir("SFTerm")
  child.no_nmap("<leader><leader>")
  child.no_nmap("<C-c>")

  child.cmd("setfiletype SFTerm")
  child.has_nmap("<leader><leader>")
  child.has_nmap("<C-c>")
end

T["setup()"]["default has a VimEnter event defined"] = function()
  eq(#child.api.nvim_get_autocmds({ event = "VimEnter", group = "SF" }), 1)
end

T["setup()"]["the VimEnter event can be disabled by custom config"] = function()
  child.sf_setup({ fetch_org_list_at_nvim_start = false })

  eq(#child.api.nvim_get_autocmds({ event = "VimEnter", group = "SF" }), 0)
end

T["setup()"]["only the placeholder command in non-sf-project dir"] = function()
  child.open_in_non_sf_dir("test.txt")

  -- `:SF` exists but is the self-explaining placeholder, not the real command.
  -- Distinguished by nargs, not `definition`: nightly reports an empty
  -- `definition` for Lua-callback commands while stable reports the desc.
  eq(child.api.nvim_get_commands({})["SF"].nargs, "*")
end

T["setup()"]["placeholder command reports why it is unavailable"] = function()
  child.open_in_non_sf_dir("test.txt")

  child.capture_notify()

  child.cmd("SF org fetchList")

  local notified = child.notified()
  eq(#notified, 1)
  expect.match(notified[1].msg, "not inside a Salesforce project")
end

T["setup()"]["has user commands in sf-project dir"] = function()
  child.open_in_sf_dir("test.txt")

  eq(child.api.nvim_get_commands({})["SF"].name, "SF")
  -- the real command, not the placeholder, which takes "*"
  eq(child.api.nvim_get_commands({})["SF"].nargs, "+")
end

T["setup() after a buffer is open"] = new_set()

T["setup() after a buffer is open"]["gives the real command and default keys in a project buffer"] = function()
  -- Lazy loading: the Apex file is open before setup() runs
  child.setup()
  child.open_in_sf_dir("SfProject.cls")
  child.sf_setup({ enable_hotkeys = true })

  eq(child.api.nvim_get_commands({})["SF"].nargs, "+")
  child.has_nmap("<leader>ss")
  child.has_nmap("<leader>sp")
end

T["setup() after a buffer is open"]["called twice keeps the real command"] = function()
  child.open_in_sf_dir("SfProject.cls")
  child.sf_setup()

  eq(child.api.nvim_get_commands({})["SF"].nargs, "+")
end

T["setup() after a buffer is open"]["keeps the placeholder outside a project"] = function()
  child.setup()
  child.open_in_non_sf_dir("test.txt")
  child.sf_setup({ enable_hotkeys = true })

  eq(child.api.nvim_get_commands({})["SF"].nargs, "*")
  child.no_nmap("<leader>ss")
end

return T
