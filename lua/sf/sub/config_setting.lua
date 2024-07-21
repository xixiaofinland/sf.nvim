local M = {}

local Sf = require('sf')
local U = require('sf.util')

local function curry(func)
  return function(a)
    return function(b)
      return func(a, b)
    end
  end
end

local complete = function(supported_args, subcmd_arg_lead)
  return vim.iter(supported_args)
      :filter(function(arg)
        return arg:find(subcmd_arg_lead) ~= nil
      end)
      :totable()
end

local complete_func = curry(complete)

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
  if arg_to_func_map[sub_cmd][arg] == nil then
    return U.show_err(arg .. ' is not a supported sub command')
  end
  arg_to_func_map[sub_cmd][arg]()
end

---@param opts table
M.create_sf_cmd = function(opts)
  local fargs = opts.fargs
  local sub_cmd = fargs[1]
  local matched_sub_cmd = M.sub_cmd_tbl[sub_cmd]

  if not matched_sub_cmd then
    return U.show_err("unknown command: " .. sub_cmd)
  end

  if #fargs ~= 2 then
    return U.show_err(sub_cmd .. " must supply one and only one argument")
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
    complete = complete_func(vim.tbl_keys(arg_to_func_map.current))
  },
}

return M
