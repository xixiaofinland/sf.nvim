local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

-- local U = require('sf.util');
local M = {};


-- function t()
--   local tbl = vim.split('aa:b::c:d:::e:f:g::', ':' )
--   for i, value in ipairs(tbl) do
--     -- print(value)
--   end
--   local s = table.concat(tbl)
--   print(s)
-- end
--
-- function a()
--   local tbl = vim.fn.readfile('./.a', '')
--   -- local tbl = vim.fn.readfile(U.get_sf_root()..'/.a', '')
--   local s = table.concat(tbl)
--   local tt = vim.json.decode(s, {})[1]
--   P(tt["manageableState"])
-- end
-- a()


M.pick_metadata = function(source, opts)
  opts = opts or {}
  pickers.new({}, {
    prompt_title = "metadata",

    finder = finders.new_table {
      results = source,
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry["fullName"],
          ordinal = entry["fullName"],
        }
      end
    },

    sorter = conf.generic_sorter(opts),

    attach_mappings = function(prompt_bufnr, map)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        print(vim.inspect(selection))
        vim.api.nvim_put({ selection[1] }, "", false, true)
      end)
      return true
    end,
  }):find()
end

return M;
