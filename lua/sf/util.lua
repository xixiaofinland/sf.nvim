local M = {}

M.get_sf_root = function()
  local root_patterns = { ".forceignore", "sfdx-project.json" }

  local root = vim.fs.dirname(vim.fs.find(root_patterns, {
    upward = true,
    stop = vim.uv.os_homedir(),
    path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
  })[1])

  if root == nil then
    error('*File not in a sf project folder*')
  end

  return root
end

M.is_sf_cmd_installed = function()
  if vim.fn.executable('sf') ~= 1 then
    error('*SF cli not found*')
  end
end

M.is_table_empty = function(tbl)
  if vim.tbl_isempty(tbl) then
    error('*Empty table*')
  end
end

M.is_empty = function(t)
  if t == '' or t == nil then
    error('*Empty value*')
  end
end

M.job_call = function(cmd, msg, err_msg, cb)
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_exit =
        function(_, code)
          if code == 0 and msg ~= nil then
            print(msg)
          elseif code ~= 0 and err_msg ~= nil then
            vim.notify(err_msg, vim.log.levels.ERROR)
          end

          if code == 0 and cb ~= nil then
            cb()
          end
        end,
  })
end

return M
