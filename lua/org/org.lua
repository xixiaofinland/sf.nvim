local O = {}
O.orgs = {}
O.target_org = nil
local A = vim.api

local cleanCache = function()
  O.orgs = {}
end

O.set = function()
  if next(O.orgs) == nil then
    A.nvim_err_writeln('No org available.')
  end

  vim.ui.select(O.orgs, {
    prompt = 'Select for local:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                O.target_org = choice
                print('target_org set')
              else
                A.nvim_err_writeln(choice .. ' - set target_org failed! Not in a sfdx project folder?')
              end
            end,
      })
    end
  end)
end

O.setGlobal = function()
  if next(O.orgs) == nil then
    A.nvim_err_writeln('No org available.')
  end

  vim.ui.select(O.orgs, {
    prompt = 'Select for Global:'
  }, function(choice)
    if choice ~= nil then
      vim.fn.jobstart('sf config set target-org --global ' .. choice, {
        on_exit =
            function(_, code)
              if code == 0 then
                O.target_org = choice
                print('Global target_org set')
              else
                A.nvim_err_writeln(' Global set target_org [' .. choice .. '] failed!')
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
      O.target_org = v.alias
      print('target_org set')
    end
    table.insert(O.orgs, v.alias)
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

O.fetch = function()
  if vim.fn.executable('sf') ~= 1 then
    A.nvim_err_writeln('sf cli command is not installed!')
    return
  end

  cleanCache()
  fetchAndStoreOrgs()
end

return O
