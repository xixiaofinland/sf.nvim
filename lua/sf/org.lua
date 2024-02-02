local U = require('sf.util');
local S = require('sf');
local T = require('sf.term')

local H = {}
H.types_to_retrieve = {
  "ApexClass",
  "ApexTrigger",
  "StaticResource",
  "LightningComponentBundle"
}

local M = {}

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

function M.select_md_to_retrieve()
  H.select_md_to_retrieve_content()
end

function M.retrieve_metadata_lists()
  H.retrieve_metadata_lists()
end

function M.retrieve_apex_under_cursor()
  H.retrieve_apex_under_cursor()
end

-- Helper --------------------

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

H.orgs = {}
local api = vim.api

H.clean_org_cache = function()
  H.orgs = {}
end

H.set_target_org = function()
  U.is_table_empty(H.orgs)

  vim.ui.select(H.orgs, {
    prompt = 'Local target_org:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                S.target_org = choice
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
    prompt = 'Global target_org:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org --global ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                S.target_org = choice
                vim.notify('Global target_org set', vim.log.levels.INFO)
              else
                vim.notify('Global set target_org [' .. choice .. '] failed!', vim.log.levels.ERROR)
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
      S.target_org = v.alias
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
  U.is_empty(S.target_org)

  H.diff_in(S.target_org)
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
            vim.cmd("vert diffsplit " .. temp_file)
            vim.notify('Retrive success: ' .. org, vim.log.levels.INFO)
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

H.select_md_to_retrieve_content = function()
  U.is_empty(S.target_org)
  local root = U.get_sf_root()

  local md_folder = root .. '/.md'
  local md_to_display = {}

  for _, type in pairs(H.types_to_retrieve) do
    local md_file = string.format('%s/%s_%s.json', md_folder, type, S.target_org)

    if vim.fn.filereadable(md_file) == 0 then
      vim.notify('%s not exist! Failed to pull?' .. md_file, vim.log.levels.WARN)
    else
      local metadata = vim.fn.readfile(md_file)
      local md_tbl = vim.json.decode(table.concat(metadata), {})

      for _, v in ipairs(md_tbl) do
        if v["manageableState"] == 'unmanaged' then
          table.insert(md_to_display, v)
        end
      end
    end
  end

  H.tele_metadata(md_to_display, {})
end

H.tele_metadata = function(source, opts)
  opts = opts or {}
  pickers.new({}, {
    prompt_title = 'Org: ' .. S.target_org,

    finder = finders.new_table {
      results = source,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry["fullName"] .. ' | ' .. entry["type"],
          ordinal = entry["fullName"] .. ' | ' .. entry["type"],
        }
      end
    },

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local md = action_state.get_selected_entry().value

        H.retrieve_md(md["type"], md["fullName"])
      end)
      return true
    end,
  }):find()
end

H.retrieve_apex_under_cursor = function()
  local current_word = vim.fn.expand('<cword>')
  print(current_word)
  H.retrieve_md('ApexClass', current_word)
end

H.retrieve_md = function(type, name)
  U.is_empty(S.target_org)
  U.get_sf_root()

  local cmd = string.format('sf project retrieve start -m %s:%s -o %s', type, name, S.target_org)
  T.run(cmd)
end

H.retrieve_metadata_lists = function()
  U.is_empty(S.target_org)
  local root = U.get_sf_root()

  local md_folder = root .. '/.md'
  if vim.fn.isdirectory(md_folder) == 0 then
    local result = vim.fn.mkdir(md_folder)
    if result == 0 then
      return vim.notify('md folder creation failed!', vim.log.levels.ERROR)
    end
  end

  for _, type in pairs(H.types_to_retrieve) do
    local md_file = string.format('%s/%s_%s.json', md_folder, type, S.target_org)

    local cmd = string.format('sf org list metadata -m %s -o %s -f %s', type, S.target_org, md_file)
    local msg = string.format('%s retrieved', type)
    local err_msg = string.format('%s retrieve failed: %s', type, md_file)

    U.job_call(cmd, msg, err_msg);
  end
end

return M
