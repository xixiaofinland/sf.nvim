local U = require('sf.util');
local Sf = {}

Sf.last_tests = ''

Sf.target_org = ''

Sf.get = function()
  U.is_empty(Sf.target_org)

  return Sf.target_org
end

-- Copy current file name without dot-after, e.g. copy "Hello" from "Hello.cls"
Sf.copy_apex_name = function()
  local file_name = vim.split(vim.fn.expand("%:t"), ".", { trimempty = true, plain = true })[1]
  vim.fn.setreg('*', file_name)
  vim.notify(string.format('"%s" copied.', file_name), vim.log.levels.INFO)
end

return Sf
