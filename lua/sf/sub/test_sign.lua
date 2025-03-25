local U = require("sf.util")
local M = {}
local H = {}
local enabled = false
local cache = nil

local covered_group = "SfCovered"
local uncovered_group = "SfUncovered"
local covered_sign = "sf_covered"
local uncovered_sign = "sf_uncovered"

local show_covered = true
local show_uncovered = true

M.covered_percent = ""

M.setup = function()
  if vim.g.sf.code_sign_highlight.covered.fg == "" then
    show_covered = false
  end

  if vim.g.sf.code_sign_highlight.uncovered.fg == "" then
    show_uncovered = false
  end

  H.highlight(covered_group, { fg = vim.g.sf.code_sign_highlight.covered.fg })
  H.highlight(uncovered_group, { fg = vim.g.sf.code_sign_highlight.uncovered.fg })

  vim.fn.sign_define(covered_sign, { text = "▎", texthl = covered_group })
  vim.fn.sign_define(uncovered_sign, { text = "▎", texthl = uncovered_group })

  local in_project, _ = pcall(U.get_sf_root)
  enabled = in_project and (vim.g.sf.auto_display_code_sign or false)
end

M.toggle = function()
  if enabled then
    vim.notify("Sign disabled.", vim.log.levels.INFO)
    H.unplace()
  else
    vim.notify("Sign enabled.", vim.log.levels.INFO)
    M.refresh_and_place()
  end
end

M.uncovered_jump_forward = function()
  local isForward = true
  H.uncovered_jump(isForward)
end

M.uncovered_jump_backward = function()
  local isForward = false
  H.uncovered_jump(isForward)
end

M.is_enabled = function()
  return enabled
end

M.refresh_and_place = function()
  H.unplace()
  local coverage = H.get_coverage()
  if coverage == nil then
    return
  end

  local signs = H.get_signs_from(coverage)
  vim.fn.sign_placelist(signs)
  enabled = true
end

M.refresh_current_file_covered_percent = function()
  local coverage = H.get_coverage()
  if coverage == nil then
    return
  end

  local file_name = vim.fn.expand("%:t")

  for i, v in pairs(coverage) do
    local apex_name = v["name"] .. ".cls"

    if file_name == apex_name then
      M.covered_percent = v["coveredPercent"]
      return
    end
  end
  M.covered_percent = ""
end

M.invalidate_cache_and_try_place = function()
  cache = nil
  if M.is_enabled() or vim.g.sf.auto_display_code_sign then
    M.refresh_and_place()
  end
end

-- helpers

H.get_signs_from = function(coverage)
  local signs = {}

  for i, v in pairs(coverage) do
    local apex_name = v["name"] .. ".cls"

    if vim.fn.expand("%:t") == apex_name then
      M.covered_percent = v["coveredPercent"]
    end

    if U.is_apex_loaded_in_buf(apex_name) then
      for line, value in pairs(v["lines"]) do
        local sign = {}
        sign.id = 0
        sign.buffer = U.get_buf_num(apex_name)
        sign.lnum = line
        sign.priority = 1000

        if show_covered and value == 1 then
          sign.name = covered_sign
          sign.group = covered_group
        elseif show_uncovered and value == 0 then
          sign.name = uncovered_sign
          sign.group = uncovered_group
        end

        table.insert(signs, sign)
      end
    end
  end
  return signs
end

H.get_coverage = function()
  local coverage

  if cache ~= nil then
    coverage = cache
    return coverage
  end

  local tbl = U.read_file_in_plugin_folder("test_result.json")
  if not tbl then
    -- vim.notify_once("Local test_result.json not found.", vim.log.levels.WARN)
    return nil
  end

  coverage = vim.tbl_get(tbl, "result", "coverage", "coverage")
  if coverage == nil then
    vim.notify_once("Local test_result.json has no coverage element.", vim.log.levels.WARN)
    return nil
  end

  cache = coverage

  return coverage
end

H.unplace = function()
  vim.fn.sign_unplace(covered_group)
  vim.fn.sign_unplace(uncovered_group)
  enabled = false
end

H.uncovered_jump = function(isForward)
  if not enabled then
    return
  end

  local placed = vim.fn.sign_getplaced("", { group = uncovered_group })
  local placed_signs = placed[1].signs

  if #placed == 0 or #placed_signs == 0 then
    return
  end

  local current_lnum = vim.fn.line(".")

  local hunks = H.get_hunks(placed_signs)

  if not isForward then
    hunks = H.revert(hunks)
  end

  for _, hunk in ipairs(hunks) do
    local hunk_start_lnum = hunk[1].lnum

    if (isForward and hunk_start_lnum > current_lnum) or (not isForward and hunk_start_lnum < current_lnum) then
      vim.fn.sign_jump(hunk[1].id, uncovered_group, "")
      return
    end
  end

  vim.fn.sign_jump(hunks[1][1].id, uncovered_group, "") -- loop back
end

H.get_hunks = function(placed_signs)
  local hunks = {}
  local current_hunk = { placed_signs[1] }

  for i = 2, #placed_signs do
    local sign = placed_signs[i]
    if sign.lnum == current_hunk[#current_hunk].lnum + 1 then
      table.insert(current_hunk, sign)
    else
      table.insert(hunks, current_hunk)
      current_hunk = { sign }
    end
  end
  table.insert(hunks, current_hunk)

  return hunks
end

H.highlight = function(group, color)
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

H.revert = function(hunks)
  table.sort(hunks, function(a, b)
    return a[1].lnum > b[1].lnum
  end)
  return hunks
end

return M
