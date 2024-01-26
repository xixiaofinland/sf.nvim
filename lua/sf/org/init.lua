local H = {}
local M = {}

function M.get()
  if H.target_org == '' then
    return ''
  end

  return '-o ' .. H.target_org
end

function M.get_target_org()
  return H.target_org
end

function M.fetch()
  H.fetch()
end

function M.set()
  H.set()
end

function M.set_global()
  H.set_global()
end

function M.diff_in_target_org()
  H.diff_in_target_org()
end

function M.diff_in()
  H.diff_in()
end

----------------- help --------------------

H.orgs = {}
H.target_org = ''
local api = vim.api

local cleanCache = function()
  H.orgs = {}
end

H.set = function()
  if next(H.orgs) == nil then
    api.nvim_err_writeln('No org available.')
  end

  vim.ui.select(H.orgs, {
    prompt = 'Select for local:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                H.target_org = choice
                -- vim.notify('target_org set', vim.log.levels.INFO)
              else
                api.nvim_err_writeln(choice .. ' - set target_org failed! Not in a sfdx project folder?')
              end
            end,
      })
    end
  end)
end

H.set_global = function()
  if next(H.orgs) == nil then
    api.nvim_err_writeln('No org available.')
  end

  vim.ui.select(H.orgs, {
    prompt = 'Select for Global:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org --global ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                H.target_org = choice
                print('Global target_org set')
              else
                api.nvim_err_writeln(' Global set target_org [' .. choice .. '] failed!')
              end
            end,
      })
    end
  end)
end

local storeOrgs = function(data)
  local s = ""
  for _, v in ipairs(data) do
    s = s .. v;
  end

  local orgData = vim.json.decode(s, {}).result.nonScratchOrgs

  for _, v in pairs(orgData) do
    if v.isDefaultUsername == true then
      H.target_org = v.alias
      -- vim.notify('target_org set', vim.log.levels.INFO)
    end
    table.insert(H.orgs, v.alias)
  end
end

local fetchAndStoreOrgs = function()
  vim.fn.jobstart('sf org list --json', {
    stdout_buffered = true,
    on_stdout =
        function(_, data)
          storeOrgs(data)
        end
  })
end

H.fetch = function()
  if vim.fn.executable('sf') ~= 1 then
    api.nvim_err_writeln('sf cli command is not installed!')
    return
  end

  cleanCache()
  fetchAndStoreOrgs()
end

H.diff_in_target_org = function()
  if H.target_org == '' then
    return vim.notify('no target org set!', vim.log.levels.ERROR)
  end
  H.diff(H.target_org)
end

H.diff_in = function()
  if next(H.orgs) == nil then
    api.nvim_err_writeln('No org available.')
  end

  vim.ui.select(H.orgs, {
    prompt = 'Select org to diff with:'
  }, function(choice)
    if choice ~= nil then
      H.diff(choice)
    end
  end)
end

H.diff = function(org)
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

  -- vim.notify(cmd, vim.log.levels.INFO)

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

return M
