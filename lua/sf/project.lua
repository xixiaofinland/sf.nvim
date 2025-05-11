local U = require("sf.util")

local Project = {}

local current_package_dir = nil

Project.get_project_file_content = function()
  local root = U.get_sf_root()

  local project_file_path = root .. "/sfdx-project.json"
  local file = io.open(project_file_path, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  local ok, parsed = pcall(vim.json.decode, content)
  if not ok then
    return nil
  end

  return parsed
end

Project.get_current_package_dir = function()
  -- return the user nominated current package
  if current_package_dir ~= nil then
    return current_package_dir
  end

  -- otherwise, return the default package from sfdx-project.json if it exists
  local root = U.get_sf_root()
  local project = Project.get_project_file_content()
  if project and project["packageDirectories"] then
    for _, dir in pairs(project["packageDirectories"]) do
      if dir["default"] then
        local package_path = root .. dir["path"] .. "/main/default"
        return U.normalize_path(package_path, true)
      end
    end
  end

  -- fall back to default_dir
  return U.get_default_dir_path()
end

Project.set_current_package_dir = function(package_name)
  local root = U.get_sf_root()

  if not U.str_ends_with(package_name, "/main/default") and not U.str_ends_with(package_name, "/main/default/") then
    package_name = package_name .. "/main/default"
  end

  current_package_dir = U.normalize_path(root .. package_name, true)
end

Project.set_current_package = function()
  local project = Project.get_project_file_content()

  local packages = {}

  if project and project["packageDirectories"] then
    for _, dir in pairs(project["packageDirectories"]) do
      table.insert(packages, dir["path"])
    end
  end

  if #packages == 0 then
    return U.show("No package directories found in sfdx-project.json")
  end

  vim.ui.select(packages, {
    prompt = "Current package:",
  }, function(choice)
    if choice ~= nil then
      Project.set_current_package_dir(choice)
    end
  end)
end

Project.get_apex_folder_path = function()
  return Project.get_current_package_dir() .. "classes/"
end

return Project
