local ts = vim.treesitter
local parsers = require('nvim-treesitter.parsers')
local parser = parsers.get_parser()
local lang = parser:lang()
local qs = [[
    (method_declaration
      (modifiers
        (annotation
          (identifier) @anno (#match? @anno "^[iI][sS][tT][eE][sS][tT]$" )))
      name: (identifier) @meth_name
    )
  ]]
local query = ts.query.parse(lang, qs)

local tree = parser:parse()[1]
local root = tree:root()


local p = function(v)
  print(vim.inspect(v))
end

local t = function(node)
  p(ts.get_node_text(node, 0))
end

local get_names_in_curr_file = function()
  local names = {}
  for _, matches, _ in query:iter_matches(root, 0) do
    local match = matches[2]
    table.insert(names, match)
  end
  return names
end

local get_curr_name= function()
  local curr_node = ts.get_node()
  while curr_node ~= nil do
    if curr_node:type() == 'method_declaration' then
      print('found!')
      -- TODO: not goining into the loop. Switch to use node:type() to match??
      for _, matches, _ in query:iter_matches(curr_node, 0) do
        local match = matches[2]
        t(match)
      end
    end
    curr_node = curr_node:parent()
  end
end

get_test_method_name_under_cursor()
