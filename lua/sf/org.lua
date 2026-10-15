local U = require("sf.util")
local B = require("sf.sub.cmd_builder")

local H = {}
local Org = {}

function Org.fetch_org_list()
  H.fetch_org_list()
end

--- Refetch the org list when the cwd moves to another sf project
function Org.on_dir_changed()
  H.on_dir_changed()
end

function Org.set_target_org()
  H.set_target_org()
end

function Org.set_global_target_org()
  H.set_global_target_org()
end

function Org.diff_in_target_org()
  H.diff_in_target_org()
end

function Org.diff_in_org()
  H.diff_in_org()
end

function Org.open()
  -- local cmd = 'sf org open -o ' .. U.get()
  local cmd = B:new():cmd("org"):act("open"):build()
  local err_msg = "Command failed: " .. cmd
  U.job_call(cmd, nil, err_msg)
end

function Org.open_current_file()
  -- local cmd = vim.fn.expandcmd('sf org open --source-file "%:p" -o ') .. U.get()
  local cmd = B:new():cmd("org"):act("open"):addParams("-f", "%:p"):build()
  local err_msg = "Command failed: " .. cmd
  U.job_call(cmd, nil, err_msg)
end

function Org.pull_log()
  H.pull_log()
end

-- helpers;

H.pull_log = function()
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end
  if not U.is_installed("fzf-lua") then
    return U.show_err("fzf-lua is not installed. Need it to show the list.")
  end

  local log_id

  local on_list = function(obj)
    local ok, log_table = pcall(vim.json.decode, obj.stdout, {})
    if not ok then
      return U.show_err("Failed to parse log JSON!")
    end

    local logs = {}
    local log_names = {}

    if #log_table["result"] == 0 then
      return U.show_warn("No logs found in org")
    end

    for _, v in ipairs(log_table["result"]) do
      local name = string.format(
        "%s | %s | %s bytes | %s",
        v["LogUser"]["Name"],
        string.gsub(v["StartTime"], "T", " "),
        v["LogLength"],
        v["Status"]
      )
      table.insert(log_names, name)
      v["User"] = v["LogUser"]["Name"]
      v["attributes"] = nil
      v["LogUser"] = nil
      logs[name] = v
    end

    require("fzf-lua").fzf_exec(log_names, {
      winopts = {
        preview = {
          layout = "vertical",
          hidden = false,
          vertical = "down:50%",
        },
      },
      preview = function(items)
        local contents = {}
        local prepend_char = ""
        vim.tbl_map(function(x)
          table.insert(contents, prepend_char .. U.table_to_string_lines(logs[x]))
          prepend_char = "\n"
        end, items)
        return contents
      end,
      actions = {
        ["default"] = function(selected)
          log_id = logs[selected[1]]["Id"]
          U.show("Downloading log...")
          local get_cmd = B:new()
            :cmd("apex")
            :act("get")
            :subact("log")
            :addParams("-i", log_id)
            :addParams("-d", U.get_plugin_folder_path() .. "logs/")
            :buildAsTable()
          U.silent_system_call(get_cmd, nil, "Failed to get logs from org", function()
            U.try_open_file(U.get_plugin_folder_path() .. "logs/" .. log_id .. ".log")
          end)
        end,
      },
    })
  end

  local cmd_tbl = B:new():cmd("apex"):act("list"):subact("log"):addParams("--json"):buildAsTable()
  U.system_call(cmd_tbl, nil, "Failed to get logs from org", on_list, "Querying logs...")
end

H.orgs = {}

-- Bumped by each fetch, so only the latest of overlapping fetches is stored
H.fetch_id = 0

-- Org entries mark scratch orgs for display; sf wants the bare name
---@param entry string
---@return string
H.org_name = function(entry)
  return (entry:gsub("^%[S%] ", ""))
end

H.set_target_org = function()
  if vim.tbl_isempty(H.orgs) then
    return U.show_err("No orgs available. Run :SF org list first.")
  end
  vim.ui.select(H.orgs, {
    prompt = "Local target_org:",
  }, function(choice)
    if choice ~= nil then
      local org = H.org_name(choice)
      local cmd = 'sf config set target-org "' .. org .. '"'
      local err_msg = org .. " - set target_org failed! Not in a sfdx project folder?"
      local cb = function()
        U.target_org = org
      end

      U.silent_job_call(cmd, nil, err_msg, cb)
    end
  end)
end

H.set_global_target_org = function()
  if vim.tbl_isempty(H.orgs) then
    return U.show_err("No orgs available. Run :SF org list first.")
  end

  vim.ui.select(H.orgs, {
    prompt = "Global target_org:",
  }, function(choice)
    if choice ~= nil then
      local org = H.org_name(choice)
      local cmd = "sf config set target-org --global " .. org
      local msg = "Global target_org set: " .. org
      local err_msg = string.format("Global set target_org [%s] failed!", org)
      local cb = function()
        U.target_org = org
      end
      U.silent_job_call(cmd, msg, err_msg, cb)
    end
  end)
end

-- Replaces the org list and target_org. A list without a default org clears
-- target_org, so one left over from another project isn't used.
---@param result { nonScratchOrgs: table[]|nil, scratchOrgs: table[]|nil }
H.store_orgs = function(result)
  local orgs = {}
  local target_org = ""

  local org_data = vim.list_extend(vim.list_extend({}, result.nonScratchOrgs or {}), result.scratchOrgs or {})
  for _, v in ipairs(org_data) do
    local alias = v.alias or v.username
    if v.isDefaultUsername then
      target_org = alias
    end

    local org_entry = v.isScratch and "[S] " .. alias or alias
    table.insert(orgs, org_entry)
  end

  H.orgs = orgs
  U.target_org = target_org
end

---@param obj vim.SystemCompleted
H.on_org_list = function(obj)
  if obj.code ~= 0 then
    local err = vim.trim(obj.stderr or "")
    return U.show_err("Failed to list orgs: " .. (err ~= "" and err or "sf exited with code " .. obj.code))
  end

  local ok, parsed = pcall(vim.json.decode, obj.stdout or "", { luanil = { object = true, array = true } })
  if not ok or type(parsed) ~= "table" or type(parsed.result) ~= "table" then
    return U.show_err("Failed to list orgs: sf output is not JSON")
  end

  H.store_orgs(parsed.result)
end

-- The sf project of the cwd, "" outside one. sf runs in the cwd, so its
-- project's local config decides the default org.
---@return string
H.cwd_project = function()
  local found = vim.fs.find({ ".forceignore", "sfdx-project.json" }, {
    upward = true,
    stop = vim.uv.os_homedir(),
    path = vim.fn.getcwd(),
  })[1]
  return found and vim.fs.dirname(found) or ""
end

-- Project whose orgs were last fetched; nil until the first fetch
H.fetched_project = nil

H.on_dir_changed = function()
  -- Never fetched: no target_org to go stale, and no sf call the user didn't ask for
  if H.fetched_project == nil then
    return
  end

  local project = H.cwd_project()
  if project == H.fetched_project then
    return
  end

  -- Cleared first, so nothing runs against the old project's org meanwhile
  H.orgs = {}
  U.target_org = ""
  H.fetched_project = project
  if vim.fn.executable("sf") == 1 then
    H.fetch_org_list()
  end
end

H.fetch_org_list = function()
  U.is_sf_cmd_installed()

  H.fetched_project = H.cwd_project()
  H.fetch_id = H.fetch_id + 1
  local fetch_id = H.fetch_id
  vim.system(
    { "sf", "org", "list", "--json", "--skip-connection-status" },
    { text = true },
    vim.schedule_wrap(function(obj)
      if fetch_id == H.fetch_id then
        H.on_org_list(obj)
      end
    end)
  )
end

H.diff_in_target_org = function()
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end

  local metadataType = H.get_current_metadata_type()
  if metadataType then
    H.diff_in(U.target_org, metadataType)
  end
end

H.diff_in_org = function()
  if vim.tbl_isempty(H.orgs) then
    return U.show_err("No orgs available. Run :SF org list first.")
  end

  -- Checked before the prompt, so the user doesn't pick an org for nothing
  local metadataType = H.get_current_metadata_type()
  if not metadataType then
    return
  end

  vim.ui.select(H.orgs, {
    prompt = "Select org to diff in:",
  }, function(choice)
    if choice ~= nil then
      H.diff_in(H.org_name(choice), metadataType)
    end
  end)
end

---@return string|nil
H.get_current_metadata_type = function()
  local metadataType = H.get_metadata_type(vim.fn.expand("%:p"))
  if metadataType == nil then
    U.show_err(string.format("Cannot diff %s: its metadata type is unknown", vim.fn.expand("%:t")))
  end
  return metadataType
end

---@param org string
---@param metadataType string
H.diff_in = function(org, metadataType)
  local file_name = vim.fn.expand("%:t")
  local file_name_no_ext = H.get_file_name_without_extension(file_name)
  local temp_path = U.get_plugin_folder_path() .. "diffs/"

  -- Create diffs folder if it doesn't exist
  if vim.fn.isdirectory(temp_path) == 0 then
    vim.fn.mkdir(temp_path, "p")
  end

  local cmd = B:new()
    :cmd("project")
    :act("retrieve start")
    :addParams({
      ["-m"] = metadataType .. ":" .. file_name_no_ext,
      ["-r"] = temp_path,
      ["--json"] = "",
    })
    :set_org(org)
    :build()

  local stdout_data = {}
  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      vim.list_extend(stdout_data, data)
    end,
    on_exit = function(_, code)
      if code ~= 0 then
        return U.show_err("Retrieve failed: " .. org)
      end

      local json_str = table.concat(stdout_data, "\n")
      local ok, parsed = pcall(vim.fn.json_decode, json_str)
      if not ok or not parsed then
        return U.show_err("Retrieve failed: could not parse sf CLI output")
      end

      local files = (parsed.result or {}).files or {}
      local retrieved_file = nil
      for _, f in ipairs(files) do
        if f.state == "Failed" then
          return U.show_err("Retrieve failed: " .. (f.error or "unknown error"))
        end
        if f.filePath and vim.fn.fnamemodify(f.filePath, ":t") == file_name then
          retrieved_file = f.filePath
        end
      end

      -- fallback for edge cases where filePath doesn't match directly
      if not retrieved_file then
        retrieved_file = H.find_file(temp_path, file_name)
      end

      if not retrieved_file then
        return U.show_err("Retrieve succeeded but file not found locally")
      end

      vim.notify("Retrieve success: " .. org, vim.log.levels.INFO)
      vim.cmd("vert diffsplit " .. vim.fn.fnameescape(retrieved_file))
      vim.bo[0].buflisted = false
    end,
  })
end

---@param fileName string
---@return any
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

-- The type comes from the first folder, below the project root, named after
-- one: a substring match would read "lwc/groupsList/" as a Group.
---@param filePath string
---@return string | nil
H.get_metadata_type = function(filePath)
  filePath = vim.fs.normalize(filePath)
  local ok, root = pcall(U.get_sf_root)
  root = ok and vim.fs.normalize(root) .. "/"
  if root and vim.startswith(filePath, root) then
    filePath = filePath:sub(#root + 1)
  end

  local folders = vim.split(vim.fs.dirname(filePath), "/", { trimempty = true })
  for _, folder in ipairs(folders) do
    if H.metadata_types[folder] then
      return H.metadata_types[folder]
    end
  end
  return nil
end

---@param path string
---@param target string
---@return string|nil
H.find_file = function(path, target)
  local scanner = vim.loop.fs_scandir(path)
  -- if scanner is nil, then path is not a valid dir
  if scanner then
    local file, type = vim.loop.fs_scandir_next(scanner)
    if path:sub(-1) ~= "/" then
      path = path .. "/"
    end
    while file do
      if type == "directory" then
        local found = H.find_file(path .. file, target)
        if found then
          return found
        end
      elseif file == target then
        return path .. file
      end
      -- get the next file and type
      file, type = vim.loop.fs_scandir_next(scanner)
    end
  end
end

return Org
