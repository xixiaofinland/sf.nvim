local T = require("sf.term")
local B = require("sf.sub.cmd_builder")
local TS = require("sf.ts")
local U = require("sf.util")
local S = require("sf.sub.test_sign")

local H = {}
local P = {}
local Test = {}

Test.is_sign_enabled = S.is_enabled
Test.refresh_and_place_sign = S.refresh_and_place
Test.setup_sign = S.setup
Test.toggle_sign = S.toggle
Test.uncovered_jump_forward = S.uncovered_jump_forward
Test.uncovered_jump_backward = S.uncovered_jump_backward
Test.refresh_current_file_covered_percent = S.refresh_current_file_covered_percent
Test.covered_percent = function()
  return S.covered_percent
end

Test.open = function()
  P.open()
end

Test.run_current_test_with_coverage = function()
  local ok_class, test_class_name = pcall(H.validateInTestClass)
  if not ok_class then
    return
  end

  local ok_method, test_name = pcall(H.validateInTestMethod)
  if not ok_method then
    return
  end

  local cmd = B:new()
    :cmd("apex")
    :act("run test")
    :addParams({
      ["-t"] = test_class_name .. "." .. test_name,
      ["-r"] = "human",
      ["-w"] = vim.g.sf.sf_wait_time,
      ["-c"] = "",
    })
    :build()

  U.last_tests = cmd
  T.run(cmd, H.save_test_coverage_locally)
end

---@param cb function
---@return nil
Test.run_current_test = function()
  local ok_class, test_class_name = pcall(H.validateInTestClass)
  if not ok_class then
    return
  end

  local ok_method, test_name = pcall(H.validateInTestMethod)
  if not ok_method then
    return
  end

  -- local cmd = string.format("sf apex run test --tests %s.%s -r human -w 5 %s-o %s", test_class_name, test_name, extraParams, U.get())
  local cmd = B:new()
    :cmd("apex")
    :act("run test")
    :addParams({
      ["-t"] = test_class_name .. "." .. test_name,
      ["-r"] = "human",
      ["-w"] = vim.g.sf.sf_wait_time,
    })
    :build()

  U.last_tests = cmd
  T.run(cmd)
end

Test.run_all_tests_in_this_file_with_coverage = function()
  local ok_class, test_class_name = pcall(H.validateInTestClass)
  if not ok_class then
    return
  end

  local cmd = B:new()
    :cmd("apex")
    :act("run test")
    :addParams({
      ["-n"] = test_class_name,
      ["-r"] = "human",
      ["-w"] = vim.g.sf.sf_wait_time,
      ["-c"] = "",
    })
    :build()

  U.last_tests = cmd
  T.run(cmd, H.save_test_coverage_locally)
end

---@param cb function
---@return nil
Test.run_all_tests_in_this_file = function(cb)
  local ok_class, test_class_name = pcall(H.validateInTestClass)
  if not ok_class then
    return
  end

  -- local cmd = string.format("sf apex run test --class-names %s -r human -w 5 %s-o %s", test_class_name, extraParams, U.get())
  local cmd = B:new()
    :cmd("apex")
    :act("run test")
    :addParams({
      ["-n"] = test_class_name,
      ["-r"] = "human",
      ["-w"] = vim.g.sf.sf_wait_time,
    })
    :build()

  U.last_tests = cmd
  T.run(cmd, cb)
end

Test.repeat_last_tests = function()
  if U.is_empty_str(U.last_tests) then
    return U.show_warn("Last test command is empty.")
  end

  T.run(U.last_tests)
end

Test.run_local_tests = function()
  -- local cmd = string.format("sf apex run test --test-level RunLocalTests --code-coverage -r human --wait 180 -o %s", U.get())
  local cmd = B:new()
    :cmd("apex")
    :act("run test")
    :addParams({
      ["-l"] = "RunLocalTests",
      ["-c"] = "",
      ["-r"] = "human",
      ["-w"] = 180,
    })
    :build()

  U.last_tests = cmd
  T.run(cmd)
end

Test.run_all_jests = function()
  T.run("npm run test:unit:coverage")
end

Test.run_jest_file = function()
  if vim.fn.expand("%"):match("(.*)%.test%.js$") == nil then
    vim.notify("Not in a jest test file", vim.log.levels.ERROR)
    return
  end
  T.run(string.format("npm run test:unit -- -- %s", vim.fn.expand("%")))
end

-- helper;

H.validateInTestClass = function()
  local test_class_name = TS.get_test_class_name()
  if U.is_empty_str(test_class_name) then
    U.notify_then_error("Not in a test class.")
  end

  return test_class_name
end

H.validateInTestMethod = function()
  local test_name = TS.get_current_test_method_name()
  if U.is_empty_str(test_name) then
    U.notify_then_error("Cursor not in a test method.")
  end

  return test_name
end

---@param lines table
---@return any
H.extract_test_run_id = function(lines)
  for _, line in ipairs(lines) do
    if string.find(line, "Test Run Id") then
      return string.match(line, "Test Run Id%s*(%w+)")
    end
  end
  return nil
end

---@param self table
---@param cmd string
---@param exit_code number
H.save_test_coverage_locally = function(self, cmd, exit_code)
  U.create_plugin_folder_if_not_exist()

  local lines = vim.api.nvim_buf_get_lines(self.buf, 0, -1, false)
  local id = H.extract_test_run_id(lines)
  if id == nil then
    return
  end

  local file_name = "test_result.json"
  -- local cmd = 'sf apex get test -i ' .. id .. ' -c --json > ' .. U.get_plugin_folder_path() .. file_name
  local cmd = B:new():cmd("apex"):act("get test"):addParams("-i", id):addParams("-c"):addParams("--json"):build()
  cmd = cmd .. " > " .. U.get_plugin_folder_path() .. file_name

  U.silent_job_call(cmd, "Code coverage saved.", "Code coverage save failed! " .. cmd, S.invalidate_cache_and_try_place)
end

-- prompt below

local api = vim.api
local buftype = "nowrite"
local filetype = "sf_test_prompt"

P.buf = nil
P.win = nil
P.class = nil
P.tests = nil
P.test_num = nil
P.selected_tests = {}

P.open = function()
  local class = TS.get_test_class_name()
  if U.is_empty_str(class) then
    U.notify_then_error("Not an Apex test class.")
  end

  local test_names = TS.get_test_method_names_in_curr_file()
  if vim.tbl_isempty(test_names) then
    U.show("no Apex test found.")
  end

  local tests = {}
  local test_num = 0
  for _, name in ipairs(test_names) do
    table.insert(tests, name)
    test_num = test_num + 1
  end

  P.class = class
  P.tests = tests
  P.test_num = test_num

  local buf = P.use_existing_or_create_buf()
  local win = P.use_existing_or_create_win()
  P.buf = buf
  P.win = win

  api.nvim_win_set_buf(win, buf)

  P.set_keys()

  vim.bo[buf].modifiable = true
  P.display()
  vim.bo[buf].modifiable = false
end

P.set_keys = function()
  vim.keymap.set("n", "x", function()
    P.toggle()
  end, { buffer = true, noremap = true })

  local create_cmd = function(tbl)
    local cmd_builder = B:new():cmd("apex"):act("run test"):addParams(tbl)

    local test_params = ""
    for _, test in ipairs(P.selected_tests) do
      test_params = test_params .. " -t " .. test
    end

    local cmd = cmd_builder:addParamStr(test_params):build()

    return cmd
  end

  vim.keymap.set("n", "cc", function()
    if vim.tbl_isempty(P.selected_tests) then
      return U.show_err("No test is selected.")
    end

    local cmd = create_cmd({ ["-w"] = vim.g.sf.sf_wait_time, ["-r"] = "human" })

    P.close()
    T.run(cmd)
    U.last_tests = cmd
    P.selected_tests = {}
  end, { buffer = true, noremap = true })

  vim.keymap.set("n", "CC", function()
    if vim.tbl_isempty(P.selected_tests) then
      return U.show_err("No test is selected.")
    end

    local cmd = create_cmd({ ["-w"] = vim.g.sf.sf_wait_time, ["-r"] = "human", ["-c"] = "" })

    P.close()
    T.run(cmd, H.save_test_coverage_locally)
    U.last_tests = cmd
    P.selected_tests = {}
  end, { buffer = true, noremap = true })
end

P.display = function()
  api.nvim_set_current_win(P.win)
  local names = {}
  table.insert(names, '** "x": toggle tests; "cc": run tests; "CC": run tests with code coverage.')

  for _, test in ipairs(P.tests) do
    local class_test = string.format("%s.%s", P.class, test)
    if vim.tbl_contains(P.selected_tests, class_test) then
      table.insert(names, "[x] " .. test)
    else
      table.insert(names, "[ ] " .. test)
    end
  end
  api.nvim_buf_set_lines(P.buf, 0, 100, false, names)
end

P.use_existing_or_create_buf = function()
  if P.buf and api.nvim_buf_is_loaded(P.buf) then
    return P.buf
  end

  local buf = api.nvim_create_buf(false, false)
  vim.bo[buf].buftype = buftype
  vim.bo[buf].filetype = filetype

  return buf
end

P.use_existing_or_create_win = function()
  local win_hight = P.test_num + 2

  if P.win and api.nvim_win_is_valid(P.win) then
    api.nvim_set_current_win(P.win)
    api.nvim_win_set_height(P.win, win_hight)
    return P.win
  end

  api.nvim_command(win_hight .. "split")

  return api.nvim_get_current_win()
end

P.toggle = function()
  if vim.bo[0].filetype ~= filetype then
    return U.show_err("file-type must be: " .. filetype)
  end

  vim.bo[0].modifiable = true

  local r, _ = unpack(vim.api.nvim_win_get_cursor(0))
  if r == 1 then -- 1st row is title
    return
  end

  local row_index = r - 1

  local curr_value = api.nvim_buf_get_text(0, row_index, 1, row_index, 2, {})

  local name = P.tests[row_index]
  local class_test = string.format("%s.%s", P.class, name)
  local index = U.list_find(P.selected_tests, class_test)

  if curr_value[1] == "x" then
    if index ~= nil then
      table.remove(P.selected_tests, index)
    end
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { " " })
  elseif curr_value[1] == " " then
    if index == nil then
      table.insert(P.selected_tests, class_test)
    end
    api.nvim_buf_set_text(0, row_index, 1, row_index, 2, { "x" })
  end

  U.show("Selected: " .. vim.tbl_count(P.selected_tests))

  vim.bo[0].modifiable = false
end

---@param param_str string
---@return nil
P.build_tests_cmd = function(param_str)
  return t
  --   local cmd = string.format('sf apex run test%s %s', t, param_str)
  --   return cmd
end

P.close = function()
  if P.win and api.nvim_win_is_valid(P.win) then
    api.nvim_win_close(P.win, false)
  end
end

return Test
