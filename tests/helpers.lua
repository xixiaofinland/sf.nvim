local Helpers = {}

Helpers.expect = vim.deepcopy(MiniTest.expect)

Helpers.expect.match = MiniTest.new_expectation("string matching", function(str, pattern)
  return str:find(pattern) ~= nil
end, function(str, pattern)
  return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
end)

Helpers.expect.no_match = MiniTest.new_expectation("no string matching", function(str, pattern)
  return str:find(pattern) == nil
end, function(str, pattern)
  return string.format("Pattern: %s\nObserved string: %s", vim.inspect(pattern), str)
end)

Helpers.new_child_neovim = function()
  local child = MiniTest.new_child_neovim()

  local prevent_hanging = function(method)
    if not child.is_blocked() then
      return
    end

    local msg = string.format("Can not use `child.%s` because child process is blocked.", method)
    error(msg)
  end

  child.setup = function()
    child.restart({ "-u", "scripts/minimal_init.lua" })
    child.bo.readonly = false
  end

  child.sf_setup = function(config)
    local req_cmd = [[require('sf').setup(...)]]
    child.lua(req_cmd, { config })
  end

  child.open_in_sf_dir = function(file, project)
    project = project or "sf-project"
    local lua_cmd = string.format("edit tests/dir/%s/%s", project, file)
    child.cmd(lua_cmd)
  end

  child.go_to_sf_dir = function()
    child.cmd("cd tests/dir/sf-project/")
  end

  child.go_to_non_sf_dir = function()
    child.cmd("cd tests/dir/non-sf-project/")
  end

  child.go_to_sf_sub_dir = function()
    child.cmd("cd tests/dir/sf-project/sf_cache/")
  end

  child.open_in_non_sf_dir = function(file)
    local lua_cmd = string.format("edit tests/dir/non-sf-project/%s", file)
    child.cmd(lua_cmd)
  end

  return child
end

return Helpers
