local U = require('sf.util');
-- local T = require('sf.term');
local H = {}
local M = {}

function M.get()
  U.is_empty(H.target_org)

  return H.target_org
end

function M.get_target_org()
  return H.target_org
end

function M.fetch_org_list()
  H.fetch_org_list()
end

function M.set_target_org()
  H.set_target_org()
end

function M.set_global_target_org()
  H.set_global_target_org()
end

function M.diff_in_target_org()
  H.diff_in_target_org()
end

function M.select_org_to_diff_in()
  H.select_org_to_diff_in()
end

function M.select_apex_to_retrieve()
  H.select_apex_to_retrieve()
end

function M.retrieve_metadata_list()
  H.retrieve_metadata_list()
end

function M.retrieve_apex_under_cursor()
  H.retrieve_apex_under_cursor()
end

----------------- Helper --------------------

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

H.orgs = {}
H.target_org = ''
local api = vim.api

H.clean_org_cache = function()
  H.orgs = {}
end

H.set_target_org = function()
  U.is_table_empty(H.orgs)

  vim.ui.select(H.orgs, {
    prompt = 'Select for local target_org:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                H.target_org = choice
              else
                api.nvim_err_writeln(choice .. ' - set target_org failed! Not in a sfdx project folder?')
              end
            end,
      })
    end
  end)
end

H.set_global_target_org = function()
  U.is_empty(H.orgs)

  vim.ui.select(H.orgs, {
    prompt = 'Select for Global target_org:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org --global ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                H.target_org = choice
                print('Global target_org set')
              else
                api.nvim_err_writeln('Global set target_org [' .. choice .. '] failed!')
              end
            end,
      })
    end
  end)
end

H.store_orgs = function(data)
  local s = ""
  for _, v in ipairs(data) do
    s = s .. v;
  end

  local org_data = vim.json.decode(s, {}).result.nonScratchOrgs

  for _, v in pairs(org_data) do
    if v.isDefaultUsername == true then
      H.target_org = v.alias
    end
    table.insert(H.orgs, v.alias)
  end

  U.is_table_empty(H.orgs)
end

H.fetch_and_store_orgs = function()
  vim.fn.jobstart('sf org list --json', {
    stdout_buffered = true,
    on_stdout =
        function(_, data)
          H.store_orgs(data)
        end
  })
end

H.fetch_org_list = function()
  U.is_sf_cmd_installed()

  H.clean_org_cache()
  H.fetch_and_store_orgs()
end

H.diff_in_target_org = function()
  U.is_empty(H.target_org)

  H.diff_in(H.target_org)
end

H.select_org_to_diff_in = function()
  U.is_table_empty(H.orgs)

  vim.ui.select(H.orgs, {
    prompt = 'Select org to diff in:'
  }, function(choice)
    if choice ~= nil then
      H.diff_in(choice)
    end
  end)
end

H.diff_in = function(org)
  local file_name = vim.fn.expand("%:t")

  local metadataType = H.get_metadata_type(vim.fn.expand("%:p"))
  local file_name_no_ext = H.get_file_name_without_extension(file_name)
  local temp_path = vim.fn.tempname()

  local cmd = string.format(
    "sf project retrieve start -m %s:%s -r %s -o %s --json",
    metadataType,
    file_name_no_ext,
    temp_path,
    org
  )

  vim.fn.jobstart(cmd, {
    on_exit =
        function(_, code)
          if code == 0 then
            local temp_file = H.find_file(temp_path, file_name)
            vim.notify('Retrive success: ' .. org, vim.log.levels.INFO)
            vim.cmd("vert diffsplit " .. temp_file)
          else
            vim.notify('Retrive failed: ' .. org, vim.log.levels.ERROR)
          end
        end,
  })
end

H.get_file_name_without_extension = function(fileName)
  -- (.-) makes the match non-greedy
  -- see https://www.lua.org/manual/5.3/manual.html#6.4.1
  return fileName:match("(.-)%.%w+%-meta%.xml$") or fileName:match("(.-)%.[^%.]+$")
end

H.metadata_types = {
  ["lwc"] = "LightningComponentBundle",
  ["aura"] = "AuraDefinitionBundle",
  ["classes"] = "ApexClass",
  ["triggers"] = "ApexTrigger",
  ["pages"] = "ApexPage",
  ["components"] = "ApexComponent",
  ["flows"] = "Flow",
  ["objects"] = "CustomObject",
  ["layouts"] = "Layout",
  ["permissionsets"] = "PermissionSet",
  ["profiles"] = "Profile",
  ["labels"] = "CustomLabels",
  ["staticresources"] = "StaticResource",
  ["sites"] = "CustomSite",
  ["applications"] = "CustomApplication",
  ["roles"] = "UserRole",
  ["groups"] = "Group",
  ["queues"] = "Queue",
}

H.get_metadata_type = function(filePath)
  for key, metadataType in pairs(H.metadata_types) do
    if filePath:find(key) then
      return metadataType
    end
  end
  return nil
end

H.find_file = function(path, target)
  local scanner = vim.loop.fs_scandir(path)
  -- if scanner is nil, then path is not a valid dir
  if scanner then
    local file, type = vim.loop.fs_scandir_next(scanner)
    while file do
      if type == "directory" then
        local found = H.find_file(path .. "/" .. file, target)
        if found then
          return found
        end
      elseif file == target then
        return path .. "/" .. file
      end
      -- get the next file and type
      file, type = vim.loop.fs_scandir_next(scanner)
    end
  end
end

H.select_apex_to_retrieve = function()
  U.is_empty(H.target_org)
  local root = U.get_sf_root()

  local metadata_file = root .. '/.metadata_' .. H.target_org
  if vim.fn.filereadable(metadata_file) == 0 then
    return vim.notify('metadata file not exist: ' .. metadata_file, vim.log.levels.ERROR)
  end

  local metadata = vim.fn.readfile(metadata_file)
  local metadata_tbl = vim.json.decode(table.concat(metadata), {})

  local unmanaged = {}
  for _, v in ipairs(metadata_tbl) do
    if v["manageableState"] == 'unmanaged' then
      table.insert(unmanaged, v)
    end
  end

  H.pick_metadata(unmanaged, {})
end

H.pick_metadata = function(source, opts)
  opts = opts or {}
  pickers.new({}, {
    prompt_title = "metadata",

    finder = finders.new_table {
      results = source,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry["fullName"],
          ordinal = entry["fullName"],
        }
      end
    },

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local md_name = action_state.get_selected_entry().display

        vim.cmd('require("sf.org").get_apex_from_target_org("' .. md_name .. '")')
      end)
      return true
    end,
  }):find()
end

H.retrieve_metadata_list = function()
  U.is_empty(H.target_org)
  local root = U.get_sf_root()

  local md_file_path = root .. '/.metadata_' .. H.target_org
  local cmd = string.format("sf org list metadata -m ApexClass -o %s -f %s", H.target_org, md_file_path)

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    -- TODO: handle error case
    on_stdout =
        function(_, data)
          vim.notify('metadata retrieved => ' .. md_file_path, vim.log.levels.INFO)
        end
  })
end

-- H.retrieve_apex = function(apex_name)
--   if H.target_org == '' then
--     return vim.notify('no target org set!', vim.log.levels.ERROR)
--   end
--
--   if U.get_sf_root() == nil then
--     return vim.notify('file not in a sf project folder!', vim.log.levels.ERROR)
--   end
--
--   local cmd = string.format("sf project retrieve start -m ApexClass:%s -o %s", apex_name, H.target_org)
--   T.run(cmd)
-- end

return M
