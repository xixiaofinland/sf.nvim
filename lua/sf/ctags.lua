local U = require("sf.util")
local M = {}

M.create = function()
  U.is_ctags_installed()
  local classes_dir = U.get_default_dir_path() .. "classes"
  local cmd = { "ctags", "--extras=+q", "--langmap=Java:+.cls.trigger", "-f", "./tags", "-R", classes_dir }
  U.silent_system_call(cmd, "Tags updated successfully.", "Error updating tags.")
end

M.create_and_list = function()
  if not U.is_installed("fzf-lua") then
    return U.show_err("fzf-lua is not installed. Need it to show the list.")
  end
  M.create()
  require("fzf-lua").tags()
end
return M
