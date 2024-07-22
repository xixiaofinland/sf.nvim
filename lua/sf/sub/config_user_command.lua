local M = {}
local Sf = require('sf')
local U = require('sf.util')

local complete = function(supported_args, subcmd_arg_lead)
  local filtered_args = vim.tbl_filter(function(arg)
    return arg:find('^' .. vim.pesc(subcmd_arg_lead)) ~= nil
  end, supported_args)

  table.sort(filtered_args)
  return filtered_args
end

local common_complete = function(sub_cmd, subcmd_arg_lead)
  return complete(vim.tbl_keys(M.sub_cmd_tbl[sub_cmd].funcs), subcmd_arg_lead)
end

local common_impl = function(sub_cmd, arg)
  local func = vim.tbl_get(M.sub_cmd_tbl, sub_cmd, 'funcs', arg)
  if not func then
    return U.show_err(string.format("'%s %s' is not a valid command", sub_cmd, arg))
  end
  func()
end


---@type table<string, {impl: fun(sub_cmd: string, arg: string): any, complete: fun(subcmd_arg_lead: string): string[], funcs: table<string, fun(...): any>}>
M.sub_cmd_tbl = {
  currentFile = {
    funcs = {
      push = Sf.save_and_push,
      retrieve = Sf.retrieve,
      diff = Sf.diff_in_target_org,
      diffIn = Sf.diff_in_org,
      RunAsAnonymous = Sf.run_anonymous
    },
    impl = common_impl,
    complete = function(subcmd_arg_lead)
      return common_complete('currentFile', subcmd_arg_lead)
    end,
  },
  md = {
    funcs = {
      pull = Sf.pull_md_json,
      list = Sf.list_md_to_retrieve
    },
    impl = common_impl,
    complete = function(subcmd_arg_lead)
      return common_complete('md', subcmd_arg_lead)
    end,
  },
  mdtype = {
    funcs = {
      retrieve = Sf.pull_md_type_json,
      list = Sf.list_md_type_to_retrieve
    },
    impl = common_impl,
    complete = function(subcmd_arg_lead)
      return common_complete('mdtype', subcmd_arg_lead)
    end,
  },
  org = {
    funcs = {
      setTarget = Sf.set_target_org,
      setGlobalTarget = Sf.set_global_target_org,
      fetchList = Sf.fetch_org_list,
      open = Sf.org_open,
      openCurrentFile = Sf.org_open_current_file
    },
    impl = common_impl,
    complete = function(subcmd_arg_lead)
      return common_complete('org', subcmd_arg_lead)
    end,
  },
  term = {
    funcs = {
      toggle = Sf.toggle_term,
      cancel = Sf.cancel,
    },
    impl = common_impl,
    complete = function(subcmd_arg_lead)
      return common_complete('term', subcmd_arg_lead)
    end,
  },
  test = {
    funcs = {
      currentTest = Sf.run_current_test,
      allTestsInThisFile = Sf.run_all_tests_in_this_file,
      select = Sf.open_test_select,
    },
    impl = common_impl,
    complete = function(subcmd_arg_lead)
      return common_complete('test', subcmd_arg_lead)
    end,
  },
  create = {
    funcs = {
      apex = Sf.create_apex_class,
      lwc = Sf.create_lwc_bundle,
      aura = Sf.create_aura_bundle,
      ctags = Sf.create_ctags,
      ctagsAndList = Sf.create_and_list_ctags,
    },
    impl = common_impl,
    complete = function(subcmd_arg_lead)
      return common_complete('create', subcmd_arg_lead)
    end,
  },
}

---@param opts table
local create_sf_cmd = function(opts)
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

M.create_user_commands = function()
  vim.api.nvim_create_user_command("SF", create_sf_cmd, {
    nargs = "+",
    desc = "Sf commands",
    bang = false, -- TODO: should we support it?
    complete = function(arg_lead, cmdline, _)
      -- sub_cmd complete
      local subcmd, subcmd_arg_lead = cmdline:match("^['<,'>]*SF[!]*%s(%S+)%s(.*)$")
      print(cmdline)
      print(arg_lead)
      if subcmd
          and subcmd_arg_lead
          and M.sub_cmd_tbl[subcmd]
          and M.sub_cmd_tbl[subcmd].complete
      then
        return M.sub_cmd_tbl[subcmd].complete(subcmd_arg_lead)
      end

      -- sub_cmd with args complete
      if cmdline:match("^['<,'>]*SF[!]*%s+%w*$") then
        print(vim.inspect(M.sub_cmd_tbl))
        local sub_cmd_keys = vim.tbl_keys(M.sub_cmd_tbl)
        return vim.iter(sub_cmd_keys)
            :filter(function(key)
              return key:find(arg_lead) ~= nil
            end)
            :totable()
      end
    end,
  })
end

return M
