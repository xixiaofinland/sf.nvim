local M = {}
local H = {}

local sf = require('sf')

---@class MyCmdSubcommand
---@field impl fun(args:string[], opts: table) The command implementation
---@field complete? fun(subcmd_arg_lead: string): string[] (optional) Command completions callback, taking the lead of the subcommand's arguments

---@type table<string, MyCmdSubcommand>
-- print(vim.inspect(opts))
M.sub_cmd_tbl = {
  current = {
    impl = function(args, opts)
      local arg = H.sub_cmd_sanity_check(opts.fargs[1], args)
      if not arg then return end

      H.switch(arg) {
        ["push"] = function()
          Sf.save_and_push()
        end,
      }
    end,
    complete = function(subcmd_arg_lead)
      return vim.iter(H.sub_cmd_args.current)
          :filter(function(install_arg)
            return install_arg:find(subcmd_arg_lead) ~= nil
          end)
          :totable()
    end,
  },
}

---@param opts table
M.create_sf_cmd = function(opts)
  local fargs = opts.fargs
  local sub_cmd = fargs[1]
  local matched_sub_cmd = M.sub_cmd_tbl[sub_cmd]

  if not matched_sub_cmd then
    vim.notify("Sf: Unknown command: " .. sub_cmd, vim.log.levels.ERROR)
    return
  end

  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  matched_sub_cmd.impl(args, opts)
end

-- helper;

H.switch = function(value)
  return function(cases)
    setmetatable(cases, cases)
    local f = cases[value]
    if f then
      f()
    end
  end
end

H.sub_cmd_args = {
  current = {
    "push",
    "retrieve",
    "diff",
    "diffWith",
  },
}

H.sub_cmd_sanity_check = function(sub_cmd, args)
  if H.is_tbl_empty(args) then
    return vim.notify("Sf: missing second parameter", vim.log.levels.ERROR)
  end

  if not H.sub_cmd_args[sub_cmd] then
    return vim.notify("Sf: unsupported second parameter", vim.log.levels.ERROR)
  end

  return args[1]
end

H.is_tbl_empty = function(tbl)
  if next(tbl) == nil then
    return true
  end
  return false
end

return M
