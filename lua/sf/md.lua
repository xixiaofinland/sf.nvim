local T = require('sf.term')
local U = require('sf.util')

local H = {}
H.md_folder_name = '/md'
H.types_to_retrieve = {}

local Md = {}

function Md.pull_md_json()
  H.pull_md_json()
end

function Md.list_md_to_retrieve()
  H.list_md_to_retrieve()
end

function Md.pull_and_list_md()
  H.pull_and_list_md()
end

function Md.pull_md_type_json()
  H.pull_md_type_json()
end

function Md.list_md_type_to_retrieve()
  H.list_md_type_to_retrieve()
end

function Md.pull_and_list_md_type()
  H.pull_md_type_json(H.list_md_type_to_retrieve)
end

function Md.retrieve_apex_under_cursor()
  H.retrieve_apex_under_cursor()
end

local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local previewers = require 'telescope.previewers'
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

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

  local cmd = string.format('sf project retrieve start -m %s:%s -o %s', type, name, U.target_org)
  T.run(cmd)
end

H.list_md_to_retrieve = function()
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  local md_to_display = {}
  local md_folder = U.get_sf_root() .. H.md_folder_name

  for _, type in pairs(H.types_to_retrieve) do
    local md_file = string.format('%s/%s_%s.json', md_folder, type, U.target_org)

    if vim.fn.filereadable(md_file) == 0 then
      -- vim.notify('%s not exist! Pulling now...', vim.log.levels.WARN)
      return H.pull_and_list_md()
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

  local p = previewers.new_buffer_previewer({
    title = "Metadata details",

    define_preview = function(self, entry)
      local data = ''
      for key, value in pairs(entry.value) do
        data = string.format('%s\n\n%s: %s', data, key, value)
      end
      vim.api.nvim_buf_set_lines(self.state.bufnr, 1, -1, true, vim.split(data, '\n'))
    end,
  })

  pickers.new({}, {
    prompt_title = 'Org: ' .. U.target_org,

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

    previewer = p,

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

-- jobstart() tracking
H.counter = 0;
H.all_spawned = false;

H.md_pull_cb = function()
  H.counter = H.counter - 1
  if H.all_spawned and H.counter == 0 then
    H.list_md_to_retrieve()
  end
end

H.pull_md_json = function()
  for _, type in pairs(H.types_to_retrieve) do
    H.pull_metadata(type)
  end
end

H.pull_and_list_md = function()
  H.counter = 0;
  H.all_spawned = false;

  for _, type in pairs(H.types_to_retrieve) do
    H.counter = H.counter + 1
    H.pull_metadata(type, H.md_pull_cb)
  end
  H.all_spawned = true
end

H.pull_metadata = function(type, cb)
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  local md_folder = U.get_sf_root() .. H.md_folder_name
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

  U.job_call(cmd, msg, err_msg, cb);
end

H.pull_md_type_json = function(cb)
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  local md_folder = U.get_sf_root() .. H.md_folder_name
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

  U.job_call(cmd, msg, err_msg, cb);
end

H.list_md_type_to_retrieve = function()
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  local md_folder = U.get_sf_root() .. H.md_folder_name
  local md_type_json = string.format('%s/%s.json', md_folder, 'metadata-types')

  if vim.fn.filereadable(md_type_json) == 0 then
    return vim.notify('Metadata-type file not exist, run`SfPullMetadataTypeList` to pull it first.', vim.log.levels
      .ERROR)
  end

  local file_content = vim.fn.readfile(md_type_json)
  local tbl = vim.json.decode(table.concat(file_content), {})
  local md_types = tbl["metadataObjects"]

  H.tele_metadata_type(md_types, {})
end

H.tele_metadata_type = function(source, opts)
  opts = opts or {}
  pickers.new({}, {
    prompt_title = 'metadata-type: ' .. U.target_org,

    finder = finders.new_table {
      results = source,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry["xmlName"],
          ordinal = entry["xmlName"],
        }
      end
    },

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local md_type = action_state.get_selected_entry().value

        H.retrieve_md_type(md_type["xmlName"])
      end)
      return true
    end,
  }):find()
end

H.retrieve_md_type = function(type)
  if U.isempty(U.target_org) then
    return U.show_err('Target_org empty!')
  end

  U.get_sf_root()

  local cmd = string.format('sf project retrieve start -m \'%s:*\' -o %s', type, U.target_org)
  T.run(cmd)
end

return Md
