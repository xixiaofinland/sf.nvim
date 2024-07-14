local U = require('sf.util')
local C = require('sf.config')

local M = {}
local ns = "sf_"
local enabled = false
local cached_signs = nil
local default_priority = 10

--- @class Sign
--- @field hl string name of the highlight group
--- @field text string text to place in sign column
--- @field priority integer? optional priority (default 10; highest wins)

--- @class SignPlace
--- @field buffer string|integer
--- @field group string
--- @field id? integer
--- @field lnum integer
--- @field name string
--- @field priority integer

local highlight = function(group, color)
  local style = color.style and "gui=" .. color.style or "gui=NONE"
  local fg = color.fg and "guifg=" .. color.fg or "guifg=NONE"
  local bg = color.bg and "guibg=" .. color.bg or "guibg=NONE"
  local sp = color.sp and "guisp=" .. color.sp or ""
  local hl = "highlight default " .. group .. " " .. style .. " " .. fg .. " " .. bg .. " " .. sp
  vim.cmd(hl)
  if color.link then
    vim.cmd("highlight default link " .. group .. " " .. color.link)
  end
end

--- Defines signs.
M.setup = function()
  highlight("SfUncovered", { fg = "#F07178" })
  vim.fn.sign_define("sf_uncovered", { text = "▎", texthl = "SfUncovered", })
  vim.fn.sign_placelist({
    {
      id = 0,
      group = "",
      name = "sf_uncovered",
      buffer = vim.fn.bufname("%"),
      lnum = 2,
      priority = 10
    },
    {
      id = 0,
      group = "",
      name = "sf_uncovered",
      buffer = vim.fn.bufname("%"),
      lnum = 1,
      priority = 10
    }
  })


  -- vim.fn.sign_place(0, "", "sf_uncovered", vim.fn.bufname("%"), { lnum = 1, priority = 10 })

  -- vim.fn.sign_define(M.name("covered"), {
  --     text = config.opts.signs.covered.text,
  --     texthl = config.opts.signs.covered.hl,
  -- })

  -- vim.fn.sign_define(M.name("partial"), {
  --     text = config.opts.signs.partial.text,
  --     texthl = config.opts.signs.partial.hl,
  -- })

  -- vim.fn.sign_placelist([{}])
end

M.parse = function()
  local path = U.get_sf_root() .. C.config.md_folder_name
  local tbl = U.read_file_json_to_tbl('test_result.json', path)
  -- local file_content = vim.fn.readfile(test_result_file)
  -- local tbl = vim.json.decode(table.concat(file_content), {})
  -- -- print(tbl["result"]["coverage"]["coverage"])
  -- return tbl["result"]["coverage"]["coverage"]
  return tbl
end

--- Places a list of signs.
--- Any previously placed signs are removed.
--- @param signs SignPlace[] (:h sign_placelist)
M.place = function(signs)
  if cached_signs ~= nil then
    M.unplace()
  end
  vim.fn.sign_placelist(signs)
  enabled = true
  cached_signs = signs
end

--- Caches signs but does not place them.
--- @param signs SignPlace[] (:h sign_placelist)
M.cache = function(signs)
  M.unplace()
  cached_signs = signs
end

--- Unplaces all coverage signs.
M.unplace = function()
  vim.fn.sign_unplace(config.opts.sign_group)
  enabled = false
end

--- Returns true if coverage signs are currently shown.
M.is_enabled = function()
  return enabled
end

--- Displays cached signs.
M.show = function()
  if enabled or cached_signs == nil then
    return
  end
  M.place(cached_signs)
end

--- Toggles the visibility of coverage signs.
M.toggle = function()
  if enabled then
    M.unplace()
  elseif cached_signs ~= nil then
    M.place(cached_signs)
  end
end

--- Turns off coverage signs and removes cached results.
M.clear = function()
  M.unplace()
  cached_signs = nil
end

--- Jumps to a sign of the given type in the given direction.
--- @param sign_type? "covered"|"uncovered" Defaults to "covered"
--- @param direction? -1|1 Defaults to 1 (forward)
M.jump = function(sign_type, direction)
  if not enabled or cached_signs == nil then
    return
  end
  local placed = vim.fn.sign_getplaced("", { group = config.opts.sign_group })
  if #placed == 0 then
    return
  end
  local current_lnum = vim.fn.line(".")
  local sign_name = M.name("covered")
  if sign_type ~= nil then
    sign_name = M.name(sign_type)
  end
  direction = direction or 1

  local placed_signs = placed[1].signs
  if direction < 0 then
    table.sort(placed_signs, function(a, b)
      return a.lnum > b.lnum
    end)
  end

  for _, sign in ipairs(placed_signs) do
    if direction > 0 and sign.lnum > current_lnum and sign_name == sign.name then
      vim.fn.sign_jump(sign.id, config.opts.sign_group, "")
      return
    elseif direction < 0 and sign.lnum < current_lnum and sign_name == sign.name then
      vim.fn.sign_jump(sign.id, config.opts.sign_group, "")
      return
    end
  end
end

--- Returns a new covered sign in the format used by sign_placelist.
--- @param buffer string|integer buffer name or id
--- @param lnum integer line number
--- @return SignPlace
M.new_covered = function(buffer, lnum)
  return {
    buffer = buffer,
    group = config.opts.sign_group,
    lnum = lnum,
    name = M.name("covered"),
    priority = config.opts.signs.covered.priority or default_priority,
  }
end

--- Returns a new uncovered sign in the format used by sign_placelist.
--- @param buffer string|integer buffer name or id
--- @param lnum integer line number
--- @return SignPlace
M.new_uncovered = function(buffer, lnum)
  return {
    buffer = buffer,
    group = config.opts.sign_group,
    lnum = lnum,
    name = M.name("uncovered"),
    priority = config.opts.signs.uncovered.priority or default_priority,
  }
end

-- --- Returns a new partial coverage sign in the format used by sign_placelist.
-- --- @param buffer string|integer buffer name or id
-- --- @param lnum integer line number
-- --- @return SignPlace
-- M.new_partial = function(buffer, lnum)
--     local priority = config.opts.signs.partial.priority
--     if priority == nil then
--         if config.opts.signs.uncovered.priority ~= nil then
--             priority = config.opts.signs.uncovered.priority + 1
--         else
--             priority = default_priority + 1
--         end
--     end
--     return {
--         buffer = buffer,
--         group = config.opts.sign_group,
--         lnum = lnum,
--         name = M.name("partial"),
--         priority = priority,
--     }
-- end

return M
