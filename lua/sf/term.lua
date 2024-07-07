local U = require('sf.util')
local Term = {}
local t

-- this function is called in config.lua
-- it's meant to delay the raw term initialization so the term_cfg is ready after user's setup() call
function Term.setup(term_cfg)
  t = require('sf.term.raw_term'):new(term_cfg)
end

function Term.toggle()
  t:toggle()
end

function Term.open()
  t:open()
end

function Term.save_and_push()
  -- vim.api.nvim_command('e') -- reload file to avoid invoking y/n pop-up in Ex
  vim.api.nvim_command('write!')
  local cmd = vim.fn.expandcmd('sf project deploy start -d "%:p" -o ') .. U.get()
  t:run(cmd)
end

function Term.push_delta()
  local cmd = vim.fn.expandcmd('sf project deploy start -o ') .. U.get()
  t:run(cmd)
end

function Term.retrieve()
  local cmd = vim.fn.expandcmd('sf project retrieve start -d "%:p" -o ') .. U.get()
  t:run(cmd)
end

function Term.retrieve_delta()
  local cmd = vim.fn.expandcmd('sf project retrieve start -o ') .. U.get()
  t:run(cmd)
end

function Term.retrieve_package()
  local cmd = vim.fn.expandcmd('sf project retrieve start -x "%:p" -o ') .. U.get()
  t:run(cmd)
end

function Term.run_anonymous()
  local cmd = vim.fn.expandcmd('sf apex run -f "%:p" -o ') .. U.get()
  t:run(cmd)
end

function Term.run_query()
  local cmd = vim.fn.expandcmd('sf data query -w 5 -f "%:p" -o ') .. U.get()
  t:run(cmd)
end

function Term.run_tooling_query()
  local cmd = vim.fn.expandcmd('sf data query -t -w 5 -f "%:p" -o ') .. U.get()
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
