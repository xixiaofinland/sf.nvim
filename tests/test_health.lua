local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local eq = helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      -- Record the report instead of rendering it
      child.lua([[
        _G.reported = {}
        for _, level in ipairs({ "ok", "warn", "error", "info", "start" }) do
          vim.health[level] = function(msg) table.insert(_G.reported, { level = level, msg = msg }) end
        end
      ]])
    end,
    post_once = child.stop,
  },
})

---@param missing string[] Parsers to report as not installed
local fake_parsers = function(missing)
  child.lua(
    [[
    local missing = ...
    package.loaded["nvim-treesitter"] = package.loaded["nvim-treesitter"] or {}
    vim.treesitter.language.add = function(lang)
      return not vim.tbl_contains(missing, lang)
    end
  ]],
    { missing }
  )
end

---@return { level: string, msg: string }[]
local parser_reports = function()
  return child.lua_get([[vim.tbl_filter(function(r) return r.msg:find("parser") end, _G.reported)]])
end

T["check()"] = new_set()

T["check()"]["reports every missing parser"] = function()
  fake_parsers({ "apex", "sosl", "sflog" })

  child.lua([[require('sf.health').check()]])

  eq(parser_reports(), {
    { level = "error", msg = "apex parser not installed in nvim-treesitter!" },
    { level = "error", msg = "sosl parser not installed in nvim-treesitter!" },
    { level = "error", msg = "sflog parser not installed in nvim-treesitter!" },
  })
end

T["check()"]["reports all parsers installed"] = function()
  fake_parsers({})

  child.lua([[require('sf.health').check()]])

  eq(parser_reports(), {
    { level = "ok", msg = "All Salesforce relevant parsers are installed in nvim-treesitter." },
  })
end

return T
