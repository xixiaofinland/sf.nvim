--- *SFTerm* The module to build an integrated terminal
--- *Sf term*
---
--- Features:
---
--- - Execute sf commands to interact with Salesforce orgs.
--- - Auto pop-up (configurable) when command execution finishes.

local S = require('sf')
local TS = require('sf.ts')
local U = require('sf.util')
local t = require('sf.term.raw_term'):new()

local Term = {}

--- Toggle the SFTerm float window.
function Term.toggle()
  t:toggle()
end

--- Open the SFTerm float window.
function Term.open()
  t:open()
end

--- Save the file in the current buffer and push to target_org. The command is sent to SFTerm.
function Term.save_and_push()
  vim.api.nvim_command('e') -- reload file or write might invoke y/n pop-up in Ex
  vim.api.nvim_command('write')
  local cmd = vim.fn.expandcmd('sf project deploy start -d %:p -o ') .. S.get()
  t:run(cmd)
end

--- Retrieve the file in the current buffer from target_org. The command is sent to SFTerm.
function Term.retrieve()
  local cmd = vim.fn.expandcmd('sf project retrieve start -d %:p -o ') .. S.get()
  t:run(cmd)
end

--- Terminate the running command in SFTerm.
function Term.cancel()
  t.is_running = false -- set the flag to stop the running task
  t:run('\3')
end

--- Enter the sf project root path in SFTerm.
function Term.go_to_sf_root()
  local root = U.get_sf_root()
  t:run('cd ' .. root)
end

--- Allows to pass the user defined command into SFTerm.
function Term.run(c)
  local cmd = vim.fn.expandcmd(c)
  t:run(cmd)
end

return Term
