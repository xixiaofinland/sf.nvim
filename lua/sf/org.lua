--- *SFOrg* The module to interact with Salesforce org
--- *Sf org*
---
--- Features:
---
--- - Retrieve org list and define target_org.
--- - Diff a file between local and org version.

local U = require('sf.util');

local H = {}
local Org = {}

--- It runs "sf org list" command under the hood and stores the org list.
--- If a target_org is found, the value is saved into "target_org" variable.
function Org.fetch_org_list()
  H.fetch_org_list()
end

--- It displays the list of orgs, and allows you to define the target_org.
--- It runs "sf config set target-org" command under the hood to set the target_org.
function Org.set_target_org()
  H.set_target_org()
end

--- sf command allows to define a global target_org.
--- It runs "sf config set target-org --global " command under the hood.
function Org.set_global_target_org()
  H.set_global_target_org()
end

--- It fetches the file in the current buffer from target_org and display in the Nvim diff mode.
--- The left window displays the target_org verison, the right window displays the local verison.
function Org.diff_in_target_org()
  H.diff_in_target_org()
end

--- Similar to |diff_in_target_org|, you can choose which org to diff with.
--- The left window displays the org verison, the right window displays the local verison.
function Org.diff_in_org()
  H.diff_in_org()
end

-- Helper --------------------
local api = vim.api

H.orgs = {}

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
                U.target_org = choice
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
                U.target_org = choice
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
      U.target_org = v.alias
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
  U.is_empty(U.target_org)

  H.diff_in(U.target_org)
end

H.diff_in_org = function()
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
            vim.bo[0].buflisted = false
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

return Org
