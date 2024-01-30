local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local U = require('sf.util');


function t()
  local tbl = vim.split('aa:b::c:d:::e:f:g::', ':' )
  for i, value in ipairs(tbl) do
    print(value)
  end
end

-- our picker function: colors
local colors = function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "colors",

    finder = finders.new_table {
      results = {
        { "red",   "#ff0000" },
        { "green", "#00ff00" },
        { "blue",  "#0000ff" },
      },
      entry_maker = function(entry)
        return {
          value = entry,
          display = entry[1],
          ordinal = entry[1],
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
-- to execute the function
-- colors(require("telescope.themes").get_dropdown {})
t()
