local M = {}

--- Return sf project root path if the file in current buffer is located in or throw the error if can't find one
---
---@return string
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

--- throw an error if sf command is not installed locally
M.is_sf_cmd_installed = function()
  if vim.fn.executable('sf') ~= 1 then
    error('*SF cli not found*')
  end
end

--- throw an error if table parameter is empty
M.is_table_empty = function(tbl)
  if next(tbl) == nil then
    error('*Empty table*')
  end
end

--- throw an error if parameter(string) is empty or nil
M.is_empty = function(t)
  if t == '' or t == nil then
    error('*Empty value*')
  end
end

--- async run a command in background and display messages according to the result
--- @param cmd string console command to run
--- @param msg string message to notify when command execution succeeds
--- @param err_msg string error message to notify when command execution fails
M.job_call = function(cmd, msg, err_msg)
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_exit =
        function(_, code)
          if code == 0 and msg ~= nil then
            -- vim.notify(msg, vim.log.levels.INFO)
            print(msg)
          elseif code ~= 0 and err_msg ~= nil then
            vim.notify(err_msg, vim.log.levels.ERROR)
          end
        end,
  })
end

return M
