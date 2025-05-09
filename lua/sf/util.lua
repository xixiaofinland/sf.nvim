local M = {}

M.last_tests = ""
M.target_org = ""

---@param msg string
M.show = function(msg)
  vim.notify(msg, vim.log.levels.INFO, { title = "sf.nvim" })
end

---@param msg string
M.show_err = function(msg)
  vim.notify(msg, vim.log.levels.ERROR, { title = "sf.nvim" })
end

---@param msg string
M.show_warn = function(msg)
  vim.notify(msg, vim.log.levels.WARN, { title = "sf.nvim" })
end

---@param msg string
M.notify_then_error = function(msg)
  local sf_msg = "Sf: " .. msg
  M.show_warn(sf_msg)
  error(sf_msg)
end

M.get = function()
  if M.is_empty_str(M.target_org) then
    error("Sf: Target_org empty!")
  end

  return M.target_org
end

M.str_ends_with = function(str, ending)
  return ending == "" or str:sub(-#ending) == ending
end

M.combine_path = function(path1, path2)
  return path1 .. "/" .. path2
end

--- Returns a normalized path, optionally with a trailing separator
-- @param path string The path to normalize
-- @param trailing_slash boolean Whether to ensure trailing slash (default: false)
-- @return string Normalized path
M.normalize_path = function(path, trailing_slash)
  local normalized = vim.fs.normalize(path)

  -- Add trailing slash if requested and not already present
  if trailing_slash and normalized:sub(-1) ~= "/" then
    normalized = normalized .. "/"
  end

  return normalized
end

--- Returns the normalized default directory path
-- @return string Normalized path with trailing separator
M.get_default_dir_path = function()
  local dir_path = M.combine_path(M.get_sf_root(), vim.g.sf.default_dir)
  return M.normalize_path(dir_path, true)
end

M.get_plugin_folder_path = function()
  local folder_path = M.combine_path(M.get_sf_root(), vim.g.sf.plugin_folder_name)
  return M.normalize_path(folder_path, true)
end

M.create_plugin_folder_if_not_exist = function()
  local cache_folder = M.get_plugin_folder_path()
  if vim.fn.isdirectory(cache_folder) == 0 then
    local ok, result = pcall(vim.fn.mkdir, cache_folder, "-p")
    if not ok then
      M.show_err("cache folder creation failed!")
      M.show_err("error: " .. result)
    end
  end
end

M.get_sf_root = function()
  local root_patterns = { ".forceignore", "sfdx-project.json" }

  local start_path = vim.fs.dirname(vim.api.nvim_buf_get_name(0))

  -- If start_path is '.', use the current working directory instead
  if start_path == "." then
    start_path = vim.fn.getcwd()
  end

  local root = vim.fs.dirname(vim.fs.find(root_patterns, {
    upward = true,
    stop = vim.uv.os_homedir(),
    path = start_path,
  })[1])

  if root == nil then
    error("File not in a sf project folder")
  end

  if root:sub(-1) ~= "/" then
    root = root .. "/"
  end

  return root
end

M.is_sf_cmd_installed = function()
  if vim.fn.executable("sf") ~= 1 then
    M.notify_then_error("sf cli not found")
  end
end

M.is_ctags_installed = function()
  if vim.fn.executable("ctags") ~= 1 then
    M.notify_then_error("ctags cli not found")
  end
end

---@param tbl table
M.is_table_empty = function(tbl)
  if vim.tbl_isempty(tbl) then
    M.notify_then_error("Empty table")
  end
end

---@param s string|nil
---@return boolean
M.is_empty_str = function(s)
  return s == nil or s == ""
end

---@param tbl table
---@param value string
---@return number|nil
M.list_find = function(tbl, value)
  for i, v in pairs(tbl) do
    if v == value then
      return i
    end
  end
end

---@param cmd string
---@param msg string|nil
---@param err_msg string|nil
---@param cb function|nil
M.silent_job_call = function(cmd, msg, err_msg, cb)
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_exit = function(_, code)
      if code == 0 and msg ~= nil then
        vim.notify(msg, vim.log.levels.INFO)
      elseif code ~= 0 and err_msg ~= nil then
        vim.notify(err_msg, vim.log.levels.ERROR)
      end

      if code == 0 and cb ~= nil then
        cb()
      end
    end,
  })
end

---@param cmd string
---@param msg string|nil
---@param err_msg string|nil
---@param cb function|nil
M.job_call = function(cmd, msg, err_msg, cb)
  vim.notify("| Async job starts...", vim.log.levels.INFO)
  M.silent_job_call(cmd, msg, err_msg, cb)
end

---@param cmd table
---@param msg string|nil
---@param err_msg string|nil
---@param cb function|nil
M.silent_system_call = function(cmd, msg, err_msg, cb)
  local system_callback = function(obj)
    if obj.code ~= 0 then
      if err_msg ~= nil then
        M.show_err(err_msg)
      end
      return
    end

    if msg ~= nil then
      M.show(msg)
    end

    if cb ~= nil then
      cb(obj)
    end
  end

  vim.system(cmd, {}, vim.schedule_wrap(system_callback))
end

---@param cmd table
---@param msg string|nil
---@param err_msg string|nil
---@param cb function|nil
M.system_call = function(cmd, msg, err_msg, cb, pre_msg)
  M.show(pre_msg or "| Async job starts...")
  M.silent_system_call(cmd, msg, err_msg, cb)
end

-- Copy current file name without dot-after, e.g. copy "Hello" from "Hello.cls"
M.copy_apex_name = function()
  local file_name = vim.split(vim.fn.expand("%:t"), ".", { trimempty = true, plain = true })[1]
  vim.fn.setreg("*", file_name)
  vim.notify(string.format('"%s" copied.', file_name), vim.log.levels.INFO)
end

---@param arg string|nil
---@param prompt string
---@param cb function
M.run_cb_with_input = function(arg, prompt, cb)
  if arg ~= nil then
    cb(arg)
  else
    vim.ui.input({ prompt = prompt }, function(input)
      if input ~= nil then
        cb(input)
      else
        return
      end
    end)
  end
end

---@param tbl table
---@return string
M.table_to_string_lines = function(tbl)
  local inspect_opts = {
    newline = "",
    indent = "",
  }

  local result = vim.inspect(tbl, inspect_opts)
  result = string.gsub(result, "^{(.*)}$", "%1") -- Remove surrounding braces
  result = string.gsub(result, "%s*=%s*", ": ") -- Change " = " between key and value to ": "
  result = string.gsub(result, ",%s*", "\n") -- Add newlines after each key=val pair, and remove commas
  result = string.gsub(result, '"', "") -- Remove quotation marks around string values
  return result
end

---@param plugin_name string
---@return boolean
M.is_installed = function(plugin_name)
  return pcall(require, plugin_name)
end

---@param name string
---@return table|nil
M.read_file_in_plugin_folder = function(name)
  M.create_plugin_folder_if_not_exist()

  local path = M.get_plugin_folder_path()
  return M.read_file_json_to_tbl(name, path)
end

---@param name string
---@param path string
---@return table|nil
M.read_file_json_to_tbl = function(name, path)
  local absolute_path = path .. name
  local err_fn = function()
    vim.notify_once("File not found: " .. absolute_path, vim.log.levels.WARN)
  end
  local content = M.read_local_file(absolute_path, err_fn)
  if content == nil then
    return nil
  end

  return M.parse_from_json_to_tbl(content)
end

--- Reads the content of a local file.
--- @param absolute_path string The path to the file.
--- @param err_fn function|nil Optional function to call in case of an error.
--- @return string|nil The file content or nil if an error occurred.
M.read_local_file = function(absolute_path, err_fn)
  local ok, content = pcall(vim.fn.readfile, absolute_path)

  if not ok then
    if type(err_fn) == "function" then
      return err_fn()
    else
      M.notify_then_error("File not found: " .. absolute_path)
    end
  end

  return content
end

---@param content string
---@return table|nil
M.parse_from_json_to_tbl = function(content)
  local json = table.concat(content)
  local ok, tbl = pcall(vim.json.decode, json, {})
  if not ok then
    M.notify_then_error("Parse file from json to tbl failed: " .. absolute_path)
  end

  return tbl
end

---@param name string
---@return boolean
M.is_apex_loaded_in_buf = function(name)
  local buf_num = M.get_apex_buf_num(name)
  return buf_num ~= -1 and vim.fn.bufloaded(buf_num) == 1
end

---@param name string
---@return integer
M.get_apex_buf_num = function(name)
  local path = vim.g.sf.default_dir .. "classes/" .. name
  return M.get_buf_num(path)
end

---@param path string
---@return integer
M.get_buf_num = function(path)
  return vim.fn.bufnr(path)
end

---@param path string
M.try_open_file = function(path)
  if M.file_readable(path) then
    local open_new_file = string.format(":e! %s", path)
    vim.cmd(open_new_file)
  end
end

---@param path string
---@return boolean
M.file_readable = function(path)
  if vim.fn.filereadable(path) == 0 then
    return false
  end
  return true
end

---@param param any
---@return boolean
M.is_function = function(param)
  return type(param) == "function"
end

-- this func is supposed to be only manually called by the plugin developer to generate plugin help.txt
M.gen_doc = function()
  if not M.is_installed("mini.doc") then
    M.notify_then_error("mini.doc not installed.")
  end

  require("mini.doc").generate({
    "lua/sf/init.lua",
  })
end

M.is_windows_os = function()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return true
  end
  return false
end

return M
