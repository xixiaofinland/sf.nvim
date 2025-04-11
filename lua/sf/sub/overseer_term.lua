local api = vim.api
local cmd = api.nvim_command

local success, overseer = pcall(require, "overseer")

local T = {}

function T:new(cfg)
  local config = cfg

  return setmetatable({
    config = config,
  }, { __index = self })
end

function T:setup(cfg)
  -- currently don't have any overseer specific config.
  return self
end

function T:run(cmd, cb)
  local task = overseer.new_task({
    cmd = cmd,
    components = { "default" },
    metadata = {
      source = "sf.nvim", -- set source so we can cancel tasks later if required
    },
  })

  local handle_callback = function(t)
    if cb ~= nil then
      cb(self, cmd, t.exit_code)
    end
  end

  task:subscribe("on_complete", handle_callback)
  task:start()

  return self
end

function T:cancel()
  -- stop all task created by this plugin
  local tasks = overseer.list_tasks()

  for i, t in ipairs(tasks) do
    if t.metadata.source == "sf.nvim" then
      t:stop()
    end
  end
end

function T:toggle()
  overseer.toggle()

  return self
end

function T:open()
  overseer.open()

  return self
end

function T:close()
  overseer.close()

  return self
end

function T:get_config()
  return self.config
end

return T
