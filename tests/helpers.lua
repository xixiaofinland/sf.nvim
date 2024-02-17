local Helpers = {}

Helpers.new_child_neovim = function()
  local child = MiniTest.new_child_neovim()

  child.setup = function()
    child.restart({'-u', 'scripts/minimal_init.lua'})
    child.bo.readonly = false
  end

  return child
end

return Helpers
