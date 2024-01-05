local ts = vim.treesitter
local parsers = require('nvim-treesitter.parsers')
local parser = parsers.get_parser()
local lang = parser:lang()
local test_annotation = [[
    (method_declaration
      (modifiers
        (annotation
          (identifier) @anno (#match? @anno "^[iI][sS][tT][eE][sS][tT]$" )))
      name: (identifier) @meth_name
    )
  ]]
local apex_test_meth_query = ts.query.parse(lang, test_annotation)

local class_name = [[
    (class_declaration
      name: (identifier) @class_name
    )
  ]]
local class_name_query = ts.query.parse(lang, class_name)

local test_class_name = [[
    (class_declaration
      (modifiers
        (annotation
          (identifier) @anno (#match? @anno "^[iI][sS][tT][eE][sS][tT]$" )))
      name: (identifier) @class_name
    )
  ]]
local test_class_name_query = ts.query.parse(lang, test_class_name)

local tree = parser:parse()[1]
local root = tree:root()

local M = {}
local H = {}

M.get_class_name = function()
  local result = H.get_matched_node_names(class_name_query, 1, root)
  if not next(result) then
    return nil
  end
  return result[1]
end

M.get_test_class_name = function()
  local result = H.get_matched_node_names(test_class_name_query, 2, root)
  if not next(result) then
    return nil
  end
  return result[1]
end

M.get_test_method_names_in_curr_file = function()
  return H.get_matched_node_names(apex_test_meth_query, 2, root)
end

M.get_curr_method_name = function()
  local curr_node = ts.get_node()
  while curr_node ~= nil do
    if curr_node:type() == 'method_declaration' then
      local names = H.get_matched_node_names(apex_test_meth_query, 2, curr_node)
      if names ~= nil then
        return names[1]
      end
    end
    curr_node = curr_node:parent()
  end
  return nil
end

--- ================== Help ========================

H.get_matched_node_names = function(query, anno_index, node)
  local names = {}
  for _, matches, _ in query:iter_matches(node, 0) do
    local name = ts.get_node_text(matches[anno_index], 0)
    table.insert(names, name)
  end
  return names
end

return M
