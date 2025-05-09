local T = require("sf.term")
local U = require("sf.util")
local P = require("sf.project")
local B = require("sf.sub.cmd_builder")
local H = {}

local Md = {}

function Md.pull_md_json()
  H.pull_md_json()
end

function Md.list_md_to_retrieve()
  H.list_md_to_retrieve()
end

function Md.pull_md_type_json()
  H.pull_md_type_json()
end

function Md.list_md_type_to_retrieve()
  H.list_md_type_to_retrieve()
end

function Md.retrieve_apex_under_cursor()
  H.retrieve_apex_under_cursor()
end

function Md.create_apex_class()
  H.create_apex_class()
end

function Md.create_aura_bundle()
  H.create_aura_bundle()
end

function Md.create_lwc_bundle()
  H.create_lwc_bundle()
end

function Md.create_trigger()
  H.create_trigger()
end

-- helper;

---@param name string
H.open_apex = function(name)
  U.try_open_file(P.get_apex_folder_path() .. name .. ".cls")
end

H.retrieve_apex_under_cursor = function()
  local current_word = vim.fn.expand("<cword>")
  H.retrieve_md("ApexClass", current_word, function()
    H.open_apex(current_word)
  end)
end

---@param type string
---@param name string
---@param cb function
---@return nil
H.retrieve_md = function(type, name, cb)
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end
  U.get_sf_root()

  local type_name = string.format("%s:%s", type, name)
  local cmd = B:new():cmd("project"):act("retrieve start"):addParamsNoExpand("-m", type_name):build()
  T.run(cmd, cb)
end

H.list_md_to_retrieve = function()
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end

  if not U.is_installed("fzf-lua") then
    return U.show_err("fzf-lua is not installed. Need it to show the list.")
  end

  local md_types = vim.g.sf.types_to_retrieve
  local md = {}
  local md_names = {}

  for _, type in pairs(md_types) do
    local file = string.format("%s_%s.json", type, U.target_org)
    local md_tbl = U.read_file_json_to_tbl(file, U.get_plugin_folder_path())

    if md_tbl ~= nil then
      for _, v in ipairs(md_tbl) do
        if v["manageableState"] ~= "installed" then
          local md_key = v["type"] .. ": " .. v["fullName"]
          md[md_key] = v
          table.insert(md_names, md_key)
        end
      end
    end
  end

  require("fzf-lua").fzf_exec(md_names, {
    actions = {
      ["default"] = function(selected)
        H.retrieve_md(md[selected[1]]["type"], md[selected[1]]["fullName"], function()
          H.open_apex(md[selected[1]]["fullName"])
        end)
      end,
    },
    fzf_opts = {
      ["--preview-window"] = "nohidden,down,50%",
      ["--preview"] = function(items)
        local contents = {}
        vim.tbl_map(function(x)
          table.insert(contents, "\n" .. U.table_to_string_lines(md[x]))
        end, items)
        return contents
      end,
    },
  })
end

H.pull_md_json = function()
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end
  local md_types = vim.g.sf.types_to_retrieve
  for _, type in pairs(md_types) do
    H.pull_metadata(type)
  end
end

---@param type string
---@return nil
H.pull_metadata = function(type)
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end

  U.create_plugin_folder_if_not_exist()

  local md_file = string.format("%s%s_%s.json", U.get_plugin_folder_path(), type, U.target_org)

  -- local cmd = string.format('sf org list metadata -m %s -o %s -f %s', type, U.target_org, md_file)
  local cmd = B:new():cmd("org"):act("list metadata"):addParams({ ["-m"] = type, ["-f"] = md_file }):build()
  local msg = string.format("%s retrieved", type)
  local err_msg = string.format("%s retrieve failed: %s", type, md_file)

  U.silent_job_call(cmd, msg, err_msg)
end

H.pull_md_type_json = function()
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end

  U.create_plugin_folder_if_not_exist()

  local metadata_types_file = string.format("%s%s.json", U.get_plugin_folder_path(), "metadata-types")
  -- local cmd = string.format('sf org list metadata-types -o %s -f %s', U.target_org, metadata_types_file)
  local cmd = B:new():cmd("org"):act("list metadata-types"):addParams("-f", metadata_types_file):build()
  local msg = "Metadata-type file retrieved"
  local err_msg = string.format("Metadata-type retrieve failed: %s", metadata_types_file)

  U.silent_job_call(cmd, msg, err_msg)
end

H.list_md_type_to_retrieve = function()
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end

  if not U.is_installed("fzf-lua") then
    return U.show_err("fzf-lua is not installed. Need it to show the list.")
  end

  local tbl = U.read_file_json_to_tbl("metadata-types.json", U.get_plugin_folder_path())
  local md_types = {}

  for _, obj in pairs(tbl["metadataObjects"]) do
    table.insert(md_types, obj["xmlName"])
  end

  require("fzf-lua").fzf_exec(md_types, {
    actions = {
      ["default"] = function(selected)
        H.retrieve_md_type(selected[1])
      end,
    },
  })
end

---@param type string
---@return nil
H.retrieve_md_type = function(type)
  if U.is_empty_str(U.target_org) then
    return U.show_err("Target_org empty!")
  end

  U.get_sf_root()

  -- local cmd = string.format('sf project retrieve start -m \'%s:*\' -o %s', type, U.target_org)
  local cmd = B:new():cmd("project"):act("retrieve start"):addParams("-m", type):build()
  T.run(cmd)
end

---@param name string
H.generate_class = function(name)
  local path = P.get_apex_folder_path()
  -- local cmd = string.format("sf apex generate class --output-dir %s --name %s", path, name)
  local cmd = B:new():cmd("apex"):act("generate class"):addParams({ ["-d"] = path, ["-n"] = name }):localOnly():build()

  U.job_call(cmd, nil, "Something went wrong creating the class", function()
    local absolute_path = path .. name .. ".cls"
    U.try_open_file(absolute_path)
  end)
end

---@param name string
H.create_apex_class = function(name)
  U.run_cb_with_input(name, "Enter Class name: ", H.generate_class)
end

---@param name string
H.generate_aura = function(name)
  -- local cmd = string.format("sf lightning generate component --output-dir %s --name %s --type aura", U.get_default_dir_path() .. "/aura", name)
  local cmd = B:new()
    :cmd("lightning")
    :act("generate component")
    :addParams({ ["-d"] = P.get_current_package_dir() .. "aura", ["-n"] = name, ["--type"] = "aura" })
    :localOnly()
    :build()
  U.silent_job_call(cmd, nil, "Something went wrong creating the Aura bundle", function()
    U.try_open_file(P.get_current_package_dir() .. "aura/" .. name .. "/" .. name .. ".cmp")
  end)
end

---@param name string
H.create_aura_bundle = function(name)
  U.run_cb_with_input(name, "Enter Aura bundle name: ", H.generate_aura)
end

---@param name string
H.generate_lwc = function(name)
  -- local cmd = string.format("sf lightning generate component --output-dir %s --name %s --type lwc", U.get_sf_root() .. vim.g.sf.default_dir .. "/lwc", name)
  local cmd = B:new()
    :cmd("lightning")
    :act("generate component")
    :addParams({ ["-d"] = P.get_current_package_dir() .. "lwc", ["-n"] = name, ["--type"] = "lwc" })
    :localOnly()
    :build()
  U.silent_job_call(cmd, nil, "Something went wrong creating the LWC bundle", function()
    U.try_open_file(P.get_current_package_dir() .. "lwc/" .. name .. "/" .. name .. ".js")
  end)
end

---@param name string
H.create_lwc_bundle = function(name)
  U.run_cb_with_input(name, "Enter LWC bundle name: ", H.generate_lwc)
end

---@param name string
H.generate_trigger = function(name)
  local cmd = B:new()
    :cmd("apex")
    :act("generate")
    :subact("trigger")
    :addParams({ ["-d"] = P.get_current_package_dir() .. "triggers", ["-n"] = name })
    :localOnly()
    :buildAsTable()

  U.silent_system_call(cmd, nil, "Something went wrong creating the trigger", function()
    U.try_open_file(P.get_current_package_dir() .. "triggers/" .. name .. ".trigger")
  end)
end

---@param name string
H.create_trigger = function(name)
  U.run_cb_with_input(name, "Enter Trigger name: ", H.generate_trigger)
end

return Md
