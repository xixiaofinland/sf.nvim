--- Salesforce metadata types that are stored inside folders.
---
--- For these metadata types, `sf org list metadata -m <type>` returns an empty
--- result. To list the components you must first list the companion
--- `<type>Folder` type, then recursively list the components for each folder
--- using `sf org list metadata -m <type> --folder <folder_name>`.
---
--- See:
---   https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/meta_folder.htm
---
--- This mirrors the approach of the Salesforce DX VSCode plugin (orgBrowser),
--- which keeps a list of the metadata types that require folders.
local M = {}

--- Metadata types that live inside a folder.
--- Key: the metadata type name (as used with `-m`).
--- Value: the companion folder type name.
M.folder_types = {
  Dashboard = 'DashboardFolder',
  Document = 'DocumentFolder',
  EmailTemplate = 'EmailTemplateFolder',
  Report = 'ReportFolder',
  ReportType = 'ReportTypeFolder',
}

--- Returns true when the given metadata type is folder-based.
---@param mdtype string the metadata type (e.g. `Dashboard`)
---@return boolean
function M.is_folder_based(mdtype)
  return M.folder_types[mdtype] ~= nil
end

--- Returns the companion folder type name (e.g. `DashboardFolder`) for a
--- folder-based type, or `nil` when the type is not folder-based.
---@param mdtype string the metadata type (e.g. `Dashboard`)
---@return string?
function M.folder_type_of(mdtype)
  return M.folder_types[mdtype]
end

--- Given a folder-based metadata type and the list of folder names returned by
--- `sf org list metadata -m <type>Folder`, return a flat list of the
--- `--folder <name>` argument pairs needed to list the components of each
--- folder.
---
--- For a non-folder-based type it returns an empty list, signalling the caller
--- to simply run `sf org list metadata -m <type>`.
---@param mdtype string the metadata type (e.g. `Dashboard`)
---@param folders string[] folder names (e.g. `{ "Unfiled$Public" }`)
---@return { string }[] list of `{ "--folder", <name> }` pairs
function M.folder_args(mdtype, folders)
  if not M.is_folder_based(mdtype) then
    return {}
  end
  local args = {}
  for _, folder in ipairs(folders) do
    args[#args + 1] = { '--folder', folder }
  end
  return args
end

return M
