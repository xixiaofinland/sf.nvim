local M = {}
local Sf = require("sf")
local U = require("sf.util")

---@param candidates string[]
---@param lead string
---@param ignore_case boolean|nil
---@return string[]
local complete = function(candidates, lead, ignore_case)
  local fold = ignore_case and string.upper or function(s)
    return s
  end
  -- Plain find, not a pattern: the lead is whatever the user typed
  local filtered = vim.tbl_filter(function(c)
    return fold(c):find(fold(lead), 1, true) == 1
  end, candidates)

  table.sort(filtered)
  return filtered
end

---@param sub_cmd string
---@return string
local action_list = function(sub_cmd)
  local actions = vim.tbl_keys(M.sub_cmd_tbl[sub_cmd].funcs)
  table.sort(actions)
  return table.concat(actions, ", ")
end

-- Only the actions in `takes_args` accept a string of extra `sf` flags; the
-- rest take no parameter or a non-string one (a callback), so extra
-- arguments to them are refused rather than passed on.
---@param sub_cmd string
---@param arg string
---@param extra string
local common_impl = function(sub_cmd, arg, extra)
  local func = M.sub_cmd_tbl[sub_cmd].funcs[arg]
  if extra == "" then
    return func()
  end
  if not vim.tbl_get(M.sub_cmd_tbl[sub_cmd], "takes_args", arg) then
    return U.show_err(string.format("'%s %s' takes no arguments, got: %s", sub_cmd, arg, extra))
  end
  func(extra)
end

local SOBJECT_CATEGORIES = { "ALL", "STANDARD", "CUSTOM" }

---@param sub_cmd string
---@param arg string
---@param extra string
local sobject_impl = function(sub_cmd, arg, extra)
  if arg ~= "refresh" then
    return common_impl(sub_cmd, arg, extra)
  end
  if extra:find("%s") then
    return U.show_err("'sobject refresh' takes at most one category: ALL, STANDARD, or CUSTOM.")
  end
  local category = extra == "" and "ALL" or extra:upper()
  if not vim.tbl_contains(SOBJECT_CATEGORIES, category) then
    return U.show_err("Invalid category: " .. extra .. ". Use ALL, STANDARD, or CUSTOM.")
  end
  M.sub_cmd_tbl[sub_cmd].funcs[arg]({ category = category })
end

---@alias SfSubCmd {impl: fun(sub_cmd: string, arg: string, extra: string), funcs: table<string, fun(...): any>, takes_args: table<string, boolean>|nil, complete_arg: (fun(action: string, lead: string): string[])|nil}
---@type table<string, SfSubCmd>
M.sub_cmd_tbl = {
  currentFile = {
    funcs = {
      push = Sf.save_and_push,
      retrieve = Sf.retrieve,
      diff = Sf.diff_in_target_org,
      diffIn = Sf.diff_in_org,
      RunAsAnonymous = Sf.run_anonymous,
    },
    takes_args = { push = true, retrieve = true },
    impl = common_impl,
  },
  md = {
    funcs = {
      pull = Sf.pull_md_json,
      list = Sf.list_md_to_retrieve,
    },
    impl = common_impl,
  },
  mdtype = {
    funcs = {
      pull = Sf.pull_md_type_json,
      list = Sf.list_md_type_to_retrieve,
    },
    impl = common_impl,
  },
  org = {
    funcs = {
      setTarget = Sf.set_target_org,
      setGlobalTarget = Sf.set_global_target_org,
      fetchList = Sf.fetch_org_list,
      open = Sf.org_open,
      openCurrentFile = Sf.org_open_current_file,
      pullLog = Sf.pull_log,
    },
    impl = common_impl,
  },
  term = {
    funcs = {
      toggle = Sf.toggle_term,
      cancel = Sf.cancel,
    },
    impl = common_impl,
  },
  test = {
    funcs = {
      currentTest = Sf.run_current_test,
      allTestsInThisFile = Sf.run_all_tests_in_this_file,
      select = Sf.open_test_select,
      allTestsInOrg = Sf.run_local_tests,
    },
    impl = common_impl,
  },
  create = {
    funcs = {
      apex = Sf.create_apex_class,
      lwc = Sf.create_lwc_bundle,
      aura = Sf.create_aura_bundle,
      ctags = Sf.create_ctags,
      ctagsAndList = Sf.create_and_list_ctags,
      trigger = Sf.create_trigger,
    },
    impl = common_impl,
  },
  sobject = {
    funcs = {
      refresh = Sf.refresh_sobjects,
    },
    impl = sobject_impl,
    complete_arg = function(action, lead)
      if action == "refresh" then
        -- Execution upper-cases the category, so match it case-insensitively too
        return complete(SOBJECT_CATEGORIES, lead, true)
      end
      return {}
    end,
  },
}

---@param opts table
local create_sf_cmd = function(opts)
  local sub_cmd, arg = opts.fargs[1], opts.fargs[2]
  -- The raw text, not the rest of fargs: rejoining fargs would drop the
  -- quotes around a flag value with spaces before it reaches the shell
  local extra = opts.args:match("^%s*%S+%s+%S+%s+(.-)%s*$") or ""

  local matched_sub_cmd = M.sub_cmd_tbl[sub_cmd]
  if not matched_sub_cmd then
    local groups = vim.tbl_keys(M.sub_cmd_tbl)
    table.sort(groups)
    return U.show_err(string.format("Unknown group '%s'. Valid groups: %s", sub_cmd, table.concat(groups, ", ")))
  end
  if not arg then
    return U.show_err(string.format("Missing action for '%s'. Valid actions: %s", sub_cmd, action_list(sub_cmd)))
  end
  if not matched_sub_cmd.funcs[arg] then
    return U.show_err(
      string.format("Unknown action '%s' for '%s'. Valid actions: %s", arg, sub_cmd, action_list(sub_cmd))
    )
  end

  matched_sub_cmd.impl(sub_cmd, arg, extra)
end

---@param cmdline string
---@return string[]
local complete_sf_cmd = function(cmdline)
  local args_str = cmdline:match("%f[%w]SF!?%s+(.*)$")
  if not args_str then
    return {}
  end
  local words = vim.split(args_str, "%s+", { trimempty = true })
  -- The word being completed is empty right after a space
  if args_str == "" or args_str:match("%s$") then
    table.insert(words, "")
  end

  local lead = words[#words]
  if #words == 1 then
    return complete(vim.tbl_keys(M.sub_cmd_tbl), lead)
  end

  local sub_cmd = M.sub_cmd_tbl[words[1]]
  if not sub_cmd then
    return {}
  end
  if #words == 2 then
    return complete(vim.tbl_keys(sub_cmd.funcs), lead)
  end
  if #words == 3 and sub_cmd.complete_arg then
    return sub_cmd.complete_arg(words[2], lead)
  end
  return {}
end

-- Registered at setup() so `:SF` outside a Salesforce project explains itself
-- instead of failing with a bare E492. Overwritten by create_user_commands()
-- as soon as a project root is detected.
M.create_placeholder_command = function()
  vim.api.nvim_create_user_command("SF", function()
    U.show_err(
      "Sf.nvim commands are unavailable: the current file and cwd are not inside a Salesforce project.\n"
        .. "A project root is a folder containing `sfdx-project.json` or `.forceignore`.\n"
        .. "cwd: "
        .. vim.fn.getcwd()
        .. "\nOpen a file inside a project, or `:cd` into one, and the commands register automatically."
    )
  end, {
    nargs = "*",
    desc = "Sf commands (unavailable outside a Salesforce project)",
  })
end

M.create_user_commands = function()
  vim.api.nvim_create_user_command("SF", create_sf_cmd, {
    nargs = "+",
    desc = "Sf commands",
    bang = false, -- TODO: should we support it?
    complete = function(_, cmdline, _)
      return complete_sf_cmd(cmdline)
    end,
  })
end

return M
