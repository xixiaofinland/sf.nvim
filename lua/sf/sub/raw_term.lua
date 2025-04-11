local api = vim.api
local cmd = api.nvim_command

local T = {}
local H = {}

function T:new(cfg)
  local config = cfg

  return setmetatable({
    win = nil,
    buf = nil,
    is_running = false,
    config = config,
  }, { __index = self })
end

function T:setup(cfg)
  if not cfg then
    return vim.notify("SFTerm: setup() is optional. Please remove it!", vim.log.levels.WARN)
  end

  self.config = vim.tbl_deep_extend("force", self.config, cfg)

  return self
end

function T:store(win, buf)
  self.win = win
  self.buf = buf

  return self
end

function T:run(cmd, cb)
  if self.is_running then
    return vim.notify("Wait the current task to finish.", vim.log.levels.WARN)
  end

  local running_buf = api.nvim_create_buf(false, true)
  vim.bo[running_buf].filetype = self.config.ft

  local running_win = nil

  if H.is_win_valid(self.win) then
    api.nvim_win_set_buf(self.win, running_buf)
    running_win = self.win
  else
    running_win = self:create_and_open_win(running_buf)
  end

  self:store(running_win, running_buf):run_after_setup(cmd, cb)

  return self
end

function T:run_after_setup(cmd, cb)
  self:remember_cursor()
  api.nvim_set_current_win(self.win)

  local echo_msg = string.gsub(cmd, '"', '\\"')
  local cmd_with_echo = ""

  if H.is_windows_os() then
    local c27 = string.char(27)
    cmd_with_echo = string.format("echo %s && %s", c27 .. "[0;35m" .. echo_msg .. c27 .. "[0m", cmd)
  else
    cmd_with_echo = string.format('echo -e "\\e[0;35m %s \\e[0m";%s', echo_msg, cmd) -- echo Cyan color
  end
  -- local cmd_with_echo = string.format('echo -e "\\e[0;35m %s \\e[0m";%s', echo_msg, cmd) -- echo Cyan color
  vim.fn.termopen(cmd_with_echo, {
    clear_env = self.config.clear_env,
    env = self.config.env,
    on_exit = function(job_id, exit_code, event_name)
      self.is_running = false
      self:close() -- hack way to scroll to end
      self:open()

      if cb ~= nil then
        cb(self, cmd, exit_code)
      end
    end,
  })

  self.is_running = true

  vim.bo[self.buf].filetype = self.config.ft -- force filetype

  self:restore_cursor()

  return self
end

function T:toggle()
  if H.is_win_valid(self.win) then
    self:close()
  else
    self:open()
  end

  return self
end

function T:open()
  if H.is_win_valid(self.win) then
    return
  end

  if not H.is_buf_valid(self.buf) then
    return vim.notify_once("Sf: no previous task. Run a terminal command to initiate the term.", vim.log.levels.WARN)
  end

  local win = self:create_and_open_win(self.buf)
  self:remember_cursor()

  api.nvim_set_current_win(win)
  self:scroll_to_end():restore_cursor()

  self:store(win, self.buf)

  return self
end

function T:close()
  if not H.is_win_valid(self.win) then
    return self
  end

  api.nvim_win_close(self.win, false)

  return self
end

function T:cancel()
  self.is_running = false -- set the flag to stop the running task
  self:run("\3")
end

function T:create_and_open_win(buf)
  local cfg = self.config

  local dim = H.get_dimension(cfg.dimensions)

  local win = api.nvim_open_win(buf, false, {
    border = cfg.border,
    relative = "editor",
    style = "minimal",
    title = "SFTerm",
    title_pos = "center",
    width = dim.width,
    height = dim.height,
    col = dim.col,
    row = dim.row,
  })

  api.nvim_win_set_option(win, "winhl", ("Normal:%s"):format(cfg.hl))
  api.nvim_win_set_option(win, "winblend", cfg.blend)

  return win
end

function T:remember_cursor()
  self.last_win = api.nvim_get_current_win()
  self.prev_win = vim.fn.winnr("#")
  self.last_pos = api.nvim_win_get_cursor(self.last_win)

  return self
end

function T:restore_cursor()
  if self.last_win and self.last_pos ~= nil then
    if self.prev_win > 0 then
      cmd(("silent! %s wincmd w"):format(self.prev_win))
    end

    if H.is_win_valid(self.last_win) then
      api.nvim_set_current_win(self.last_win)
      api.nvim_win_set_cursor(self.last_win, self.last_pos)
    end

    self.last_win = nil
    self.prev_win = nil
    self.last_pos = nil
  end

  return self
end

function T:get_config()
  return self.config
end

function T:scroll_to_end()
  cmd("$")
  return self
end

-- helper -------------------

function H.is_win_valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

function H.is_buf_valid(buf)
  return buf and vim.api.nvim_buf_is_loaded(buf)
end

function H.get_dimension(opts)
  -- get lines and columns
  local cl = vim.o.columns
  local ln = vim.o.lines

  -- calculate our floating window size
  local width = math.ceil(cl * opts.width)
  local height = math.ceil(ln * opts.height - 4)

  -- and its starting position
  local col = math.ceil((cl - width) * opts.x)
  local row = math.ceil((ln - height) * opts.y - 1)

  return {
    width = width,
    height = height,
    col = col,
    row = row,
  }
end

function H.is_windows_os()
  if vim.fn.has("win32") == 1 then
    return true
  end
  return false
end

return T
