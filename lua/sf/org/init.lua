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

function M.setGlobal()
  H.setGlobal()
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

H.setGlobal = function()
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

return M
