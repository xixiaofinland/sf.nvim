local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local expect, eq = MiniTest.expect, MiniTest.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup({ default_dir = "foo/main/default" })
      child.lua([[Sf = require('sf')]])
      child.lua([[M = require('sf.org')]])
      child.lua([[P = require('sf.project')]])
    end,
    post_once = child.stop,
  },
})

local str_ends_with = function(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

T["get_current_package_dir"] = new_set()

T["get_current_package_dir"]["sfdx-project.json with packages, returns default package"] = function()
  child.open_in_sf_dir("SfProject.cls", "sf-project-2")
  local dir = child.lua("return Sf.get_current_package_dir()")
  eq(str_ends_with(dir, "/packages/package1/main/default/"), true)
end

T["get_current_package_dir"]["sfdx-project.json with packages, returns package override"] = function()
  child.open_in_sf_dir("SfProject.cls", "sf-project-2")

  child.lua('Sf.set_current_package_dir("package2")')

  local dir = child.lua("return Sf.get_current_package_dir()")
  eq(str_ends_with(dir, "/package2/main/default/"), true)
end

T["get_current_package_dir"]["sfdx-project.json with no packages, returns fallback"] = function()
  child.open_in_sf_dir("SfProject.cls")
  local dir = child.lua("return Sf.get_current_package_dir()")
  eq(str_ends_with(dir, "/foo/main/default/"), true)
end

return T
