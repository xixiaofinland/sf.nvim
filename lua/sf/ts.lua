local ts = vim.treesitter

local M = {}
local H = {}

M.get_class_name = function()
  local class = H.find_nodes("class_declaration")[1]
  return class and H.name_of(class) or nil
end

M.get_test_class_name = function()
  for _, class in ipairs(H.find_nodes("class_declaration")) do
    if H.is_test_class(class) then
      return H.name_of(class)
    end
  end
  return nil
end

M.get_test_method_names_in_curr_file = function()
  local names = {}
  for _, method in ipairs(H.find_nodes("method_declaration")) do
    if H.is_test(method) then
      table.insert(names, H.name_of(method))
    end
  end
  return names
end

M.get_current_test_method_name = function()
  local node = H.get_node_at_cursor()
  while node ~= nil do
    -- The innermost method decides: a helper method is not a test even when
    -- it sits in a test class.
    if node:type() == "method_declaration" then
      return H.is_test(node) and H.name_of(node) or nil
    end
    node = node:parent()
  end
  return nil
end

-- Helper ------------------------------

H.get_parser = function()
  local ok, parser = pcall(ts.get_parser, 0)
  if not ok or not parser then
    error("Treesitter parser not available. Ensure nvim-treesitter main is installed and a parser is loaded.")
  end
  return parser
end

H.get_root = function()
  return H.get_parser():parse()[1]:root()
end

---@param node_type string
---@return TSNode[]
H.find_nodes = function(node_type)
  local query = ts.query.parse(H.get_parser():lang(), "(" .. node_type .. ") @node")
  local nodes = {}
  for _, node in query:iter_captures(H.get_root(), 0) do
    table.insert(nodes, node)
  end
  return nodes
end

H.get_node_at_cursor = function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  return H.get_root():named_descendant_for_range(row - 1, col, row - 1, col)
end

H.name_of = function(declaration)
  local name = declaration:field("name")[1]
  return name and ts.get_node_text(name, 0) or nil
end

-- Before `@IsTest` existed, a class was a test class by holding `testMethod`
-- methods. Only its own methods count, so an inner test class doesn't make
-- its outer class one.
H.is_test_class = function(class)
  if H.is_test(class) then
    return true
  end
  local body = class:field("body")[1]
  if body == nil then
    return false
  end
  for member in body:iter_children() do
    if member:type() == "method_declaration" and H.is_test(member) then
      return true
    end
  end
  return false
end

-- Matches on the modifiers' text rather than their node shapes, so the
-- annotation (any casing, with or without arguments such as
-- `@IsTest(SeeAllData=true)`) and the legacy `testMethod` keyword are found
-- the same way.
H.is_test = function(declaration)
  for child in declaration:iter_children() do
    if child:type() == "modifiers" then
      local text = ts.get_node_text(child, 0):lower()
      return text:find("@%s*istest%f[^%w_]") ~= nil or text:find("%f[%w_]testmethod%f[^%w_]") ~= nil
    end
  end
  return false
end

return M
