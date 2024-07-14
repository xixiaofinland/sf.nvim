local T = require('sf.term')
local U = require('sf.util')
local C = require('sf.config')
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

H.retrieve_apex_under_cursor = function()
  local current_word = vim.fn.expand('<cword>')
  print(current_word)
  H.retrieve_md('ApexClass', current_word)
end

H.retrieve_md = function(type, name)
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end
  U.get_sf_root()

  local cmd = string.format('sf project retrieve start -m \'%s:%s\' -o %s', type, name, U.target_org)
  T.run(cmd)
end

H.list_md_to_retrieve = function()
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  if not U.is_installed('fzf-lua') then
    return U.show_err('fzf-lua is not installed. Need it to show the list.')
  end

  local md_folder = U.get_sf_root() .. C.config.md_folder_name

  local md_types = C.config.types_to_retrieve
  local md = {}
  local md_names = {}

  for _, type in pairs(md_types) do
    local md_file = string.format('%s/%s_%s.json', md_folder, type, U.target_org)

    if vim.fn.filereadable(md_file) == 0 then
      return U.show_err(string.format('%s not exists locally. Pull it again.', type))
    end

    local metadata = vim.fn.readfile(md_file)
    local md_tbl = vim.json.decode(table.concat(metadata), {})

    for _, v in ipairs(md_tbl) do
      if v["manageableState"] == 'unmanaged' then
        md[v["fullName"]] = v
        table.insert(md_names, v["fullName"])
      end
    end
  end

  require("fzf-lua").fzf_exec(md_names, {
    actions = {
      ['default'] = function(selected)
        print(md[selected[1]])
        print(selected[1])
        H.retrieve_md(md[selected[1]]["type"], selected[1])
      end
    },
    fzf_opts = {
      ['--preview-window'] = 'nohidden,down,50%',
      ['--preview'] = function(items)
        local contents = {}
        vim.tbl_map(function(x)
          table.insert(contents, "\n" .. U.table_to_string_lines(md[x]))
        end, items)
        return contents
      end
    },
  })
end

H.pull_md_json = function()
  local md_types = C.config.types_to_retrieve
  for _, type in pairs(md_types) do
    H.pull_metadata(type)
  end
end

H.pull_metadata = function(type)
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  local md_folder = U.get_sf_root() .. C.config.md_folder_name
  if vim.fn.isdirectory(md_folder) == 0 then
    local result = vim.fn.mkdir(md_folder)
    if result == 0 then
      return vim.notify('md folder creation failed!', vim.log.levels.ERROR)
    end
  end

  local md_file = string.format('%s/%s_%s.json', md_folder, type, U.target_org)

  local cmd = string.format('sf org list metadata -m %s -o %s -f %s', type, U.target_org, md_file)
  local msg = string.format('%s retrieved', type)
  local err_msg = string.format('%s retrieve failed: %s', type, md_file)

  U.silent_job_call(cmd, msg, err_msg);
end

H.pull_md_type_json = function()
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  local md_folder = U.get_sf_root() .. C.config.md_folder_name
  if vim.fn.isdirectory(md_folder) == 0 then
    local result = vim.fn.mkdir(md_folder)
    if result == 0 then
      return vim.notify('md folder creation failed!', vim.log.levels.ERROR)
    end
  end

  local metadata_types_file = string.format('%s/%s.json', md_folder, 'metadata-types')
  local cmd = string.format('sf org list metadata-types -o %s -f %s', U.target_org, metadata_types_file)
  local msg = 'Metadata-type file retrieved'
  local err_msg = string.format('Metadata-type retrieve failed: %s', metadata_types_file)

  U.silent_job_call(cmd, msg, err_msg);
end

H.list_md_type_to_retrieve = function()
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  if not U.is_installed('fzf-lua') then
    return U.show_err('fzf-lua is not installed. Need it to show the list.')
  end

  local md_folder = U.get_sf_root() .. C.config.md_folder_name
  local md_type_json = string.format('%s/%s.json', md_folder, 'metadata-types')

  if vim.fn.filereadable(md_type_json) == 0 then
    return vim.notify('Metadata-type file not exist, run`SfPullMetadataTypeList` to pull it first.', vim.log.levels
      .ERROR)
  end

  local file_content = vim.fn.readfile(md_type_json)
  local tbl = vim.json.decode(table.concat(file_content), {})

  local md_types = {}

  for _, obj in pairs(tbl["metadataObjects"]) do
    table.insert(md_types, obj["xmlName"])
  end

  require("fzf-lua").fzf_exec(md_types, {
    actions = {
      ['default'] = function(selected)
        H.retrieve_md_type(selected[1])
      end
    }
  })
end

H.retrieve_md_type = function(type)
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  U.get_sf_root()

  local cmd = string.format('sf project retrieve start -m \'%s:*\' -o %s', type, U.target_org)
  T.run(cmd)
end

H.generate_class = function(name)
  local path = U.get_sf_root() .. C.config.default_dir .. "/classes"
  local cmd = string.format("sf apex generate class --output-dir %s --name %s", path, name)
  U.job_call(
    cmd,
    nil,
    "Something went wrong creating the class",
    function()
      local open_new_file = string.format(":e %s/%s.cls", path, name)
      vim.cmd(open_new_file)
    end
  )
end

H.create_apex_class = function(name)
  U.run_cb_with_input(name, "Enter Class name: ", H.generate_class)
end

H.generate_aura = function(name)
  local cmd = string.format("sf lightning generate component --output-dir %s --name %s --type aura",
    U.get_sf_root() .. C.config.default_dir .. "/aura", name)
  U.silent_job_call(
    cmd,
    nil,
    "Something went wrong creating the Aura bundle",
    function()
      vim.notify("Aura bundle " .. name .. " created", vim.log.levels.INFO)
    end
  )
end

H.create_aura_bundle = function(name)
  U.run_cb_with_input(name, "Enter Aura bundle name: ", H.generate_aura)
end

H.generate_lwc = function(name)
  local cmd = string.format("sf lightning generate component --output-dir %s --name %s --type lwc",
    U.get_sf_root() .. C.config.default_dir .. "/lwc", name)
  U.silent_job_call(
    cmd,
    nil,
    "Something went wrong creating the LWC bundle",
    function()
      vim.notify("LWC bundle " .. name .. " created", vim.log.levels.INFO)
    end
  )
end

H.create_lwc_bundle = function(name)
  U.run_cb_with_input(name, "Enter LWC bundle name: ", H.generate_lwc)
end

return Md
