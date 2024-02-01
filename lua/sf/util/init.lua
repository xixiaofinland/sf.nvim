local M = {}

M.get_sf_root = function()
  local root_patterns = { ".forceignore", "sfdx-project.json" }

  local root = vim.fs.dirname(vim.fs.find(root_patterns, {
    upward = true,
    stop = vim.uv.os_homedir(),
    path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
  })[1])

  if root == nil then
    error('File not in a sf project folder!')
  end

  return root
end

M.is_sf_cmd_installed = function()
  if vim.fn.executable('sf') ~= 1 then
    error('sf cli is not installed!')
  end
end

M.is_table_empty = function(tbl)
  if next(tbl) == nil then
    error('table is empty')
  end
end

M.is_empty = function(t)
  if t == '' or t == nil then
    error('Empty value')
  end
end

return M
