local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
local new_set = MiniTest.new_set

-- A throwaway sf project in a temp dir, made the cwd, so tests can write its
-- cache files without touching tests/dir.
---@param dir_name string|nil Last path segment of the project root
---@return string root
local make_project = function(dir_name)
  return child.lua(
    [[
    local root = vim.fn.tempname() .. "/" .. ...
    vim.fn.mkdir(root .. "/sf_cache", "p")
    -- Resolved, as buffer names are (macOS's /tmp is a symlink)
    root = vim.uv.fs_realpath(root)
    vim.fn.writefile({ "{}" }, root .. "/sfdx-project.json")
    vim.cmd.cd(vim.fn.fnameescape(root))
    return root
  ]],
    { dir_name or "project" }
  )
end

---@param root string
---@param name string
---@param lines string[]
local write_cache_file = function(root, name, lines)
  child.lua([[local path, lines = ... vim.fn.writefile(lines, path)]], { root .. "/sf_cache/" .. name, lines })
end

-- fzf-lua isn't a test dependency; record what would be listed instead.
local stub_fzf = function()
  child.lua([[
    _G.fzf_items = nil
    package.loaded["fzf-lua"] = { fzf_exec = function(items) _G.fzf_items = items end }
  ]])
end

---@return string
local notified_msgs = function()
  return table.concat(
    vim.tbl_map(function(n)
      return n.msg
    end, child.notified()),
    "\n"
  )
end

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup({})
      child.lua([[Sf = require('sf')]])
      child.lua([[require('sf.util').target_org = 'test-org']])
      child.capture_notify()
      stub_fzf()
    end,
    post_once = child.stop,
  },
})

T["list_md_type_to_retrieve()"] = new_set()

T["list_md_type_to_retrieve()"]["lists the cached metadata types"] = function()
  local root = make_project()
  write_cache_file(root, "metadata-types.json", {
    '{"metadataObjects": [{"xmlName": "ApexClass"}, {"xmlName": "CustomObject"}]}',
  })

  child.lua([[Sf.list_md_type_to_retrieve()]])

  eq(child.lua_get("_G.fzf_items"), { "ApexClass", "CustomObject" })
end

T["list_md_type_to_retrieve()"]["reports a malformed cache file"] = function()
  local root = make_project()
  write_cache_file(root, "metadata-types.json", { "{not json" })

  child.lua([[Sf.list_md_type_to_retrieve()]])

  eq(child.lua_get("_G.fzf_items"), vim.NIL)
  local msgs = notified_msgs()
  expect.match(msgs, "Parse file from json to tbl failed: .*sf_cache/metadata%-types%.json")
end

T["list_md_type_to_retrieve()"]["reports a cache file without metadataObjects"] = function()
  local root = make_project()
  write_cache_file(root, "metadata-types.json", { '{"status": 1}' })

  child.lua([[Sf.list_md_type_to_retrieve()]])

  eq(child.lua_get("_G.fzf_items"), vim.NIL)
  expect.match(notified_msgs(), "No metadataObjects in .*metadata%-types%.json")
end

T["list_md_type_to_retrieve()"]["tells how to fetch a missing cache file"] = function()
  make_project()

  child.lua([[Sf.list_md_type_to_retrieve()]])

  eq(child.lua_get("_G.fzf_items"), vim.NIL)
  expect.match(notified_msgs(), ":SF mdtype pull")
end

T["list_md_to_retrieve()"] = new_set()

T["list_md_to_retrieve()"]["skips a malformed cache file with a message"] = function()
  local root = make_project()
  child.lua([[vim.g.sf = vim.tbl_extend("force", vim.g.sf, { types_to_retrieve = { "ApexClass", "ApexPage" } })]])
  write_cache_file(root, "ApexClass_test-org.json", { "{not json" })
  write_cache_file(root, "ApexPage_test-org.json", { '[{"type": "ApexPage", "fullName": "Home"}]' })

  child.lua([[Sf.list_md_to_retrieve()]])

  eq(child.lua_get("_G.fzf_items"), { "ApexPage: Home" })
  expect.match(notified_msgs(), "Parse file from json to tbl failed: .*ApexClass_test%-org%.json")
end

T["try_open_file()"] = new_set({
  parametrize = { { "with space" }, { "100%done" }, { "issue#1" } },
})

T["try_open_file()"]["opens a path containing special characters"] = function(dir_name)
  local root = make_project(dir_name)
  local path = root .. "/Hello.cls"
  child.lua([[vim.fn.writefile({ "public class Hello {}" }, ...)]], { path })

  child.lua([[require('sf.util').try_open_file(...)]], { path })

  eq(child.lua_get("vim.api.nvim_buf_get_name(0)"), path)
  eq(child.lua_get("vim.api.nvim_buf_get_lines(0, 0, -1, false)"), { "public class Hello {}" })
end

return T
