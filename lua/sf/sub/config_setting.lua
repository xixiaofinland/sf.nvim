local M = {}
local Sf = require('sf')
local U = require('sf.util')

local complete = function(supported_args, subcmd_arg_lead)
  return vim.tbl_filter(function(arg)
    return arg:find('^' .. vim.pesc(subcmd_arg_lead)) ~= nil
  end, supported_args)
end

-- sub commands' arg mapping to corresponding function
local arg_to_func_map = {
  current = {
    push = Sf.save_and_push,
    retrieve = Sf.retrieve,
    diff = Sf.diff_in_target_org,
    diffIn = Sf.diff_in_org,
  },
}

local impl_func = function(sub_cmd, arg)
  if vim.tbl_get(arg_to_func_map, sub_cmd, arg) == nil then
    return U.show_err(string.format("'%s %s' is not valid command", sub_cmd, arg))
  end
  arg_to_func_map[sub_cmd][arg]()
end

---@param opts table
M.create_sf_cmd = function(opts)
  local fargs = opts.fargs
  if #fargs ~= 2 then
    return U.show_err("Command must supply two and only two arguments")
  end

  local sub_cmd = fargs[1]
  local matched_sub_cmd = M.sub_cmd_tbl[sub_cmd]
  if not matched_sub_cmd then
    return U.show_err("unknown command: " .. sub_cmd)
  end

  matched_sub_cmd.impl(fargs[1], fargs[2])
end

---@class MyCmdSubcommand
---@field impl fun(sub_cmd:string, arg:string) The command implementation
---@field complete fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments
---@type table<string, MyCmdSubcommand>

M.sub_cmd_tbl = {
  current = {
    impl = impl_func,
    complete = function(subcmd_arg_lead)
      return complete(vim.tbl_keys(arg_to_func_map.current), subcmd_arg_lead)
    end,
  },
}

return M
