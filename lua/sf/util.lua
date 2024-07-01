local M = {}

M.cmd_params = '-w 5 -r human'
M.cmd_coverage_params = '-w 5 -r human -c'

M.last_tests = ''
M.target_org = ''

M.show = function(msg)
  vim.notify(msg, vim.log.levels.INFO)
end

M.show_err = function(msg)
  vim.notify(msg, vim.log.levels.ERROR)
end

M.show_warn = function(msg)
  vim.notify(msg, vim.log.levels.WARN)
end

M.get = function()
  if M.isempty(M.target_org) then
    error('::Target_org empty!')
  end

  return M.target_org
end

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

M.is_ctags_installed = function()
  if vim.fn.executable('ctags') ~= 1 then
    error('*ctags cli not found*')
  end
end

M.is_table_empty = function(tbl)
  if vim.tbl_isempty(tbl) then
    error('*Empty table*')
  end
end

M.isempty = function(s)
  return s == nil or s == ''
end

M.is_empty = function(t)
  if t == '' or t == nil then
    error('*Empty value*')
  end
end

M.list_find = function(tbl, value)
  for i, v in pairs(tbl) do
    if v == value then
      return i
    end
  end
end

M.removeKey = function(table, key)
  local element = table[key]
  table[key] = nil
  return element
end

M.silent_job_call = function(cmd, msg, err_msg, cb)
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

M.job_call = function(cmd, msg, err_msg, cb)
  vim.notify('| Async job starts...', vim.log.levels.INFO);
  M.silent_job_call(cmd, msg, err_msg, cb)
end

-- Copy current file name without dot-after, e.g. copy "Hello" from "Hello.cls"
M.copy_apex_name = function()
  local file_name = vim.split(vim.fn.expand("%:t"), ".", { trimempty = true, plain = true })[1]
  vim.fn.setreg('*', file_name)
  vim.notify(string.format('"%s" copied.', file_name), vim.log.levels.INFO)
end

M.run_cb_with_input = function(arg, prompt, cb)
  if arg ~= nil then
    cb(arg)
  else
    vim.ui.input(
      { prompt = prompt },
      function(input)
        if input ~= nil then
          cb(input)
        else
          return
        end
      end
    )
  end
end

M.table_to_string_lines = function(tbl)
  local result = ""
  for key, value in pairs(tbl) do
    result = result .. key .. ": " .. tostring(value) .. "\n"
  end
  return result
end

M.is_installed = function(plugin_name)
  return pcall(require, plugin_name)
end

return M
