local U = require('sf.util')
local M = {}

M.create = function()
  U.is_ctags_installed();

  local cmd = 'ctags --extras=+q --langmap=java:.cls.trigger -f ./tags -R **/main/default/classes/**'
  vim.fn.jobstart(cmd, {
    on_exit = function(_, code, _)
      if code == 0 then
        vim.notify("Tags updated successfully.", vim.log.levels.INFO)
      else
        vim.notify("Error updating tags.", vim.log.levels.ERROR)
      end
    end
  })
end

M.create_and_list = function()
  if not U.is_installed('fzf-lua') then
    return U.show_err('fzf-lua is not installed. Need it to show the list.')
  end
  M.create()
  require('fzf-lua').tags()
end
return M
