local M = {}
local H = {}

local Sf = require('sf')
local U = require('sf.util')

M.sub_cmd_tbl = H.sub_cmd_tbl

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

  matched_sub_cmd.impl(fargs[2])
end

-- helper;

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

H.complete_func = curry(complete)

H.sub_cmd_args = {
  current = {
    "push",
    "retrieve",
    "diff",
    "diffIn",
  },
}

---@class MyCmdSubcommand
---@field impl fun(args:string[]) The command implementation
---@field complete fun(subcmd_arg_lead: string): string[] Command completions callback, taking the lead of the subcommand's arguments

---@type table<string, MyCmdSubcommand>
-- print(vim.inspect(opts))
H.sub_cmd_tbl = {
  current = {
    impl = function(arg)
      U.switch(arg) {
        ["push"] = function()
          Sf.save_and_push()
        end,
        ["retrieve"] = function()
          Sf.retrieve()
        end,
        ["diff"] = function()
          Sf.diff_in_target_org()
        end,
        ["diffIn"] = function()
          Sf.diff_in_org()
        end,
        __index = function()
          U.show_err("not supported argument")
        end
      }
    end,
    complete = H.complete_func(H.sub_cmd_args.current)
  },
}

return M
