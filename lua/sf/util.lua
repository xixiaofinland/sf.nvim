local M = {}

M.cmd_params = '-w 5 -r human'
M.cmd_coverage_params = '-w 5 -r human -c'

M.last_tests = ''
M.target_org = ''

M.show = function(msg)
  vim.notify("Sf: " .. msg, vim.log.levels.INFO, { title = 'sf.nvim' })
end

M.show_err = function(msg)
  vim.notify("Sf: " .. msg, vim.log.levels.ERROR, { title = 'sf.nvim' })
end

M.show_warn = function(msg)
  vim.notify("Sf: " .. msg, vim.log.levels.WARN, { title = 'sf.nvim' })
end

M.get = function()
  if M.isempty(M.target_org) then
    error('Sf: Target_org empty!')
  end

  return M.target_org
end

M.get_default_dir_path = function()
  return M.get_sf_root() .. vim.g.sf.default_dir
end

M.get_apex_folder_path = function()
  return M.get_default_dir_path() .. 'classes/'
end

M.get_plugin_folder_path = function()
  return M.get_sf_root() .. vim.g.sf.plugin_folder_name
end

M.create_plugin_folder_if_not_exist = function()
  local cache_folder = M.get_plugin_folder_path()
  if vim.fn.isdirectory(cache_folder) == 0 then
    local result = vim.fn.mkdir(cache_folder)
    if result == 0 then
      return vim.notify('cache folder creation failed!', vim.log.levels.ERROR)
    end
  end
end

M.get_sf_root = function()
  local root_patterns = { ".forceignore", "sfdx-project.json" }

  local root = vim.fs.dirname(vim.fs.find(root_patterns, {
    upward = true,
    stop = vim.uv.os_homedir(),
    path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
  })[1])

  if root == nil then
    error('Sf: File not in a sf project folder')
  end

  return root
end

M.is_sf_cmd_installed = function()
  if vim.fn.executable('sf') ~= 1 then
    error('Sf: sf cli not found')
  end
end

M.is_ctags_installed = function()
  if vim.fn.executable('ctags') ~= 1 then
    error('Sf: ctags cli not found')
  end
end

M.is_table_empty = function(tbl)
  if vim.tbl_isempty(tbl) then
    error('Sf: Empty table')
  end
end

M.isempty = function(s)
  return s == nil or s == ''
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

M.read_file_in_plugin_folder = function(name)
  M.create_plugin_folder_if_not_exist()

  local path = M.get_plugin_folder_path()
  return M.read_file_json_to_tbl(name, path)
end

M.read_file_json_to_tbl = function(name, path)
  local absolute_path = path .. name
  local content = M.read_local_file(absolute_path)
  return M.parse_from_json_to_tbl(content)
end

M.read_local_file = function(absolute_path)
  local ok, content = pcall(vim.fn.readfile, absolute_path)
  if not ok then
    error('Sf: File not found: ' .. absolute_path)
  end

  return content
end

M.parse_from_json_to_tbl = function(content)
  local json = table.concat(content)
  local ok, tbl = pcall(vim.json.decode, json, {})
  if not ok then
    error('Sf: Parse file from json to tbl failed: ' .. absolute_path)
  end

  return tbl
end

M.is_apex_loaded_in_buf = function(name)
  local buf_num = M.get_apex_buf_num(name)
  return buf_num ~= -1 and vim.fn.bufloaded(buf_num) == 1
end

M.get_apex_buf_num = function(name)
  local path = vim.g.sf.default_dir .. "classes/" .. name
  return M.get_buf_num(path)
end

M.get_buf_num = function(path)
  return vim.fn.bufnr(path)
end

M.try_open_file = function(path)
  if M.file_readable(path) then
    local open_new_file = string.format(":e %s", path)
    vim.cmd(open_new_file)
  end
end

M.file_readable = function(path)
  if vim.fn.filereadable(path) == 0 then
    return false
  end
  return true
end

-- Mimic switch statement: https://gist.github.com/FreeBirdLjj/6303864
M.switch = function(value)
  return function(cases)
    setmetatable(cases, cases)
    local f = cases[value]
    if f then
      f()
    end
  end
end

return M
