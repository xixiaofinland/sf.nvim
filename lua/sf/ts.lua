local ts = vim.treesitter
local parsers = require("nvim-treesitter.parsers")

local M = {}
local H = {}

M.get_class_name = function()
  local class_name = [[
    (class_declaration
      name: (identifier) @class_name
    )
  ]]
  local class_name_query = H.build_query(class_name)
  local root = parsers.get_parser():parse()[1]:root()

  local result = H.get_matched_node_names(class_name_query, 1, root)
  if not next(result) then
    return nil
  end
  return result[1]
end

M.get_test_class_name = function()
  local test_class_name = [[
    (class_declaration
      (modifiers
        (annotation
          (identifier) @anno (#match? @anno "^[iI][sS][tT][eE][sS][tT]$" )))
      name: (identifier) @class_name
    )
  ]]
  local test_class_name_query = H.build_query(test_class_name)
  local root = parsers.get_parser():parse()[1]:root()

  local result = H.get_matched_node_names(test_class_name_query, 2, root)
  if vim.tbl_isempty(result) then
    return nil
  end
  return result[1]
end

M.get_test_method_names_in_curr_file = function()
  local test_annotation = [[
    (method_declaration
      (modifiers
        (annotation
          (identifier) @anno (#match? @anno "^[iI][sS][tT][eE][sS][tT]$" )))
      name: (identifier) @meth_name
    )
  ]]
  local apex_test_meth_query = H.build_query(test_annotation)
  local root = parsers.get_parser():parse()[1]:root()

  return H.get_matched_node_names(apex_test_meth_query, 2, root)
end

M.get_current_test_method_name = function()
  local test_annotation = [[
    (method_declaration
      (modifiers
        (annotation
          (identifier) @anno (#match? @anno "^[iI][sS][tT][eE][sS][tT]$" )))
      name: (identifier) @meth_name
    )
  ]]
  local apex_test_meth_query = H.build_query(test_annotation)

  local curr_node = ts.get_node()
  while curr_node ~= nil do
    if curr_node:type() == "method_declaration" then
      local names = H.get_matched_node_names(apex_test_meth_query, 2, curr_node)
      if names ~= nil then
        return names[1]
      end
    end
    curr_node = curr_node:parent()
  end
  return nil
end

-- Helper ------------------------------

H.build_query = function(query_str)
  local parser = parsers.get_parser()
  local lang = parser:lang()
  return ts.query.parse(lang, query_str)
end

H.get_matched_node_names = function(query, anno_index, node)
  local names = {}
  for _, match, _ in query:iter_matches(node, 0) do
    local raw_node = match[anno_index]
    local target_node = raw_node
    -- https://github.com/xixiaofinland/sf.nvim/issues/281
    -- in Nvim 0.11, the query capture match is wrapped into a table
    -- Checking the types to support older versions too
    if type(raw_node) == "table" and raw_node.id == nil and raw_node[1] ~= nil then
      target_node = raw_node[1]
    end

    if not target_node then
      print("match[" .. anno_index .. "] is nil")
    else
      local ok, text = pcall(ts.get_node_text, target_node, 0)
      print(ok and "Text: " .. text or ("get_node_text() failed: " .. text))
      if ok then table.insert(names, text) end
    end
  end
  return names
end

return M
