local U = require('sf.util')
local t = require('sf.term.raw_term'):new()

local Term = {}

function Term.toggle()
  t:toggle()
end

function Term.open()
  t:open()
end

function Term.save_and_push()
  vim.api.nvim_command('e') -- reload file to avoid invoking y/n pop-up in Ex
  vim.api.nvim_command('write')
  local cmd = vim.fn.expandcmd('sf project deploy start -d %:p -o ') .. U.get()
  t:run(cmd)
end

function Term.retrieve()
  local cmd = vim.fn.expandcmd('sf project retrieve start -d %:p -o ') .. U.get()
  t:run(cmd)
end

function Term.cancel()
  t.is_running = false -- set the flag to stop the running task
  t:run('\3')
end

function Term.go_to_sf_root()
  local root = U.get_sf_root()
  t:run('cd ' .. root)
end

function Term.run(c)
  local cmd = vim.fn.expandcmd(c)
  t:run(cmd)
end

return Term
