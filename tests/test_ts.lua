local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local eq = MiniTest.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.lua([[TS = require('sf.ts')]])
    end,
    post_once = child.stop,
  },
})

local set_apex = function(lines)
  child.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  child.bo.filetype = "apex"
end

-- Puts the cursor on the first occurrence of `text` in the buffer.
local cursor_on = function(text)
  local lines = child.api.nvim_buf_get_lines(0, 0, -1, false)
  for i, line in ipairs(lines) do
    local col = line:find(text, 1, true)
    if col then
      child.api.nvim_win_set_cursor(0, { i, col - 1 })
      return
    end
  end
  error("not in buffer: " .. text)
end

local test_class_name = function()
  return child.lua_get("TS.get_test_class_name()")
end

local test_method_names = function()
  return child.lua_get("TS.get_test_method_names_in_curr_file()")
end

local current_test_method_name = function()
  return child.lua_get("TS.get_current_test_method_name()")
end

T["parsers"] = new_set({ parametrize = { { "apex" }, { "soql" }, { "sosl" } } })

T["parsers"]["load from the pinned build"] = function(lang)
  local path = child.lua_get(string.format([[vim.api.nvim_get_runtime_file('parser/%s.so', false)[1] ]], lang))
  eq(path:find("/deps/parsers/parser/" .. lang .. ".so", 1, true) ~= nil, true)
  eq(child.lua_get(string.format([[(pcall(vim.treesitter.language.add, '%s'))]], lang)), true)
end

T["test class"] = new_set()

T["test class"]["@IsTest"] = function()
  set_apex({
    "@IsTest",
    "private class AccountTest {",
    "  @IsTest",
    "  static void createsAccount() {}",
    "  @isTest static void updatesAccount() {}",
    "  static void helper() {}",
    "}",
  })
  eq(test_class_name(), "AccountTest")
  eq(test_method_names(), { "createsAccount", "updatesAccount" })
end

T["test class"]["@IsTest(SeeAllData=true)"] = function()
  set_apex({
    "@IsTest(SeeAllData=true)",
    "private class AccountTest {",
    "  @IsTest(SeeAllData=true)",
    "  static void createsAccount() {}",
    "}",
  })
  eq(test_class_name(), "AccountTest")
  eq(test_method_names(), { "createsAccount" })
end

T["test class"]["legacy testMethod keyword"] = function()
  set_apex({
    "@IsTest",
    "private class AccountTest {",
    "  static testMethod void createsAccount() {}",
    "  public static TESTMETHOD void updatesAccount() {}",
    "  static void helper() {}",
    "}",
  })
  eq(test_class_name(), "AccountTest")
  eq(test_method_names(), { "createsAccount", "updatesAccount" })
end

-- Before `@IsTest` existed, a class was a test class by holding test methods.
T["test class"]["legacy testMethod keyword without a class annotation"] = function()
  set_apex({
    "public class AccountTest {",
    "  static testMethod void createsAccount() {}",
    "}",
  })
  eq(test_class_name(), "AccountTest")
  eq(test_method_names(), { "createsAccount" })
end

-- `sf apex run test` runs top-level classes only, so inner classes never
-- count as test classes, whatever they are annotated with.
T["test class"]["inner test class in a non-test outer class"] = function()
  set_apex({
    "public class Outer {",
    "  public void work() {}",
    "  @IsTest",
    "  class InnerTest {",
    "    @IsTest",
    "    static void works() {}",
    "  }",
    "}",
  })
  eq(test_class_name(), vim.NIL)
  eq(test_method_names(), {})
end

T["test class"]["inner class of a test class"] = function()
  set_apex({
    "@IsTest",
    "private class AccountTest {",
    "  @IsTest",
    "  static void createsAccount() {}",
    "  class Fixture {",
    "    @IsTest",
    "    static void build() {}",
    "  }",
    "}",
  })
  eq(test_class_name(), "AccountTest")
  eq(test_method_names(), { "createsAccount" })
  cursor_on("build")
  eq(current_test_method_name(), vim.NIL)
end

T["test class"]["two top-level classes"] = function()
  set_apex({
    "public class Service {",
    "  public void work() {}",
    "}",
    "@IsTest",
    "private class ServiceTest {",
    "  @IsTest",
    "  static void works() {}",
    "}",
  })
  eq(test_class_name(), "ServiceTest")
  eq(test_method_names(), { "works" })
end

T["test class"]["no test class"] = function()
  set_apex({
    "public class Service {",
    "  public void work() {}",
    "}",
  })
  eq(test_class_name(), vim.NIL)
  eq(test_method_names(), {})
end

T["test method under cursor"] = new_set({
  hooks = {
    pre_case = function()
      set_apex({
        "@IsTest",
        "private class AccountTest {",
        "  @IsTest",
        "  static void createsAccount() {",
        "    Account a = new Account();",
        "    if (a != null) {",
        "      for (Integer i = 0; i < 2; i++) {",
        "        insert a;",
        "      }",
        "    }",
        "  }",
        "  static void helper() {",
        "    Integer helperCount = 1;",
        "  }",
        "}",
      })
    end,
  },
})

T["test method under cursor"]["inside a test method"] = function()
  cursor_on("Account a")
  eq(current_test_method_name(), "createsAccount")
end

T["test method under cursor"]["inside a nested block of a test method"] = function()
  cursor_on("insert a")
  eq(current_test_method_name(), "createsAccount")
end

T["test method under cursor"]["inside a non-test helper method"] = function()
  cursor_on("helperCount")
  eq(current_test_method_name(), vim.NIL)
end

T["test method under cursor"]["running it from a helper method warns instead of erroring"] = function()
  child.lua([[require('sf').setup({})]])
  child.capture_notify()
  cursor_on("helperCount")

  eq(child.lua_get([[(pcall(require('sf').run_current_test))]]), true)
  eq(child.notified(), { { msg = "Sf: Cursor not in a test method.", level = child.lua_get("vim.log.levels.WARN") } })
end

return T
