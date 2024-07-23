local U = require('sf.util')
local M = {}

M.create = function()
  U.is_ctags_installed();
  local cmd = string.format('ctags --extras=+q --langmap=java:.cls.trigger -f ./tags -R **%sclasses/**', vim.g.sf.default_dir)
  U.silent_job_call(cmd, "Tags updated successfully.", "Error updating tags.")
end

M.create_and_list = function()
  if not U.is_installed('fzf-lua') then
    return U.show_err('fzf-lua is not installed. Need it to show the list.')
  end
  M.create()
  require('fzf-lua').tags()
end
return M
