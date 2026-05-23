local U = require("sf.util")

local Sobject = {}
local H = {}

local BATCH_SIZE = 25
local BATCH_CONCURRENCY = 15
local INDENT = "    "
local MODIFIER = "global"

local HEADER = [[// This file is generated as an Apex representation of the
//     corresponding sObject and its fields.
// This read-only file is used by the Apex Language Server to
//     provide code smartness, and is deleted each time you
//     refresh your sObject definitions.
// To edit your sObjects and their fields, edit the corresponding
//     .object-meta.xml and .field-meta.xml files.

]]

-- Mirrors VSCode's TYPE_MAPPING in declarationGenerator.ts. Case-sensitive
-- because Salesforce's describe returns "anyType" with a capital T while every
-- other type comes back lowercase.
local TYPE_MAPPING = {
  string = "String",
  double = "Double",
  reference = "",
  boolean = "Boolean",
  currency = "Decimal",
  date = "Date",
  datetime = "Datetime",
  email = "String",
  location = "Location",
  percent = "Double",
  phone = "String",
  picklist = "String",
  multipicklist = "String",
  textarea = "String",
  encryptedstring = "String",
  url = "String",
  id = "Id",
  base64 = "Blob",
  address = "Address",
  int = "Integer",
  anyType = "Object",
  combobox = "String",
  time = "Time",
  complexvalue = "Object",
}

---@param s string
local function capitalize(s)
  if #s == 0 then
    return s
  end
  return s:sub(1, 1):upper() .. s:sub(2)
end

---@param name string
local function strip_id(name)
  if name:sub(-2) == "Id" then
    return name:sub(1, -3)
  end
  return name
end

---@param describe_type string
local function get_target_type(describe_type)
  return TYPE_MAPPING[describe_type] or capitalize(describe_type)
end

---@param comment string|nil
---@return string
local function sanitize_comment(comment)
  if type(comment) ~= "string" or comment == "" then
    return ""
  end
  -- Match VSCode: replaceAll(/(\/\*+\/)|(\/\*+)|(\*+\/)/g, '')
  local out = comment
  out = out:gsub("/%*+/", "")
  out = out:gsub("/%*+", "")
  out = out:gsub("%*+/", "")
  return out
end

---@param field table
---@return table[]
local function generate_field_decls(field)
  local decls = {}
  local comment = sanitize_comment(field.inlineHelpText)

  if not field.referenceTo or #field.referenceTo == 0 then
    local apex_type
    if field.extraTypeInfo == "externallookup" then
      apex_type = "String"
    else
      apex_type = get_target_type(field.type or "")
    end
    table.insert(decls, {
      modifier = MODIFIER,
      type = apex_type,
      name = field.name,
      comment = comment,
    })
    return decls
  end

  local rel_type
  if #field.referenceTo > 1 then
    rel_type = "SObject"
  else
    rel_type = field.referenceTo[1]
  end
  table.insert(decls, {
    modifier = MODIFIER,
    type = rel_type,
    name = (field.relationshipName and field.relationshipName ~= vim.NIL and field.relationshipName)
      or strip_id(field.name),
    comment = comment,
  })
  -- The id-bearing field itself is always "Id" in Apex regardless of describe type.
  table.insert(decls, {
    modifier = MODIFIER,
    type = "Id",
    name = field.name,
    comment = comment,
  })
  return decls
end

---@param rel table
---@return table
local function generate_child_rel_decl(rel)
  local name = (rel.relationshipName and rel.relationshipName ~= vim.NIL and rel.relationshipName)
    or strip_id(rel.field or "")
  return {
    modifier = MODIFIER,
    type = "List<" .. rel.childSObject .. ">",
    name = name,
  }
end

---@param sobject table
---@return table
local function generate_sobject_definition(sobject)
  local decls = {}
  for _, field in ipairs(sobject.fields or {}) do
    for _, decl in ipairs(generate_field_decls(field)) do
      table.insert(decls, decl)
    end
  end
  local with_name = {}
  local without_name = {}
  for _, rel in ipairs(sobject.childRelationships or {}) do
    if type(rel.childSObject) == "string" then
      if rel.relationshipName and rel.relationshipName ~= vim.NIL and rel.relationshipName ~= "" then
        table.insert(with_name, rel)
      elseif type(rel.field) == "string" and rel.field ~= "" then
        table.insert(without_name, rel)
      end
    end
  end
  for _, rel in ipairs(with_name) do
    table.insert(decls, generate_child_rel_decl(rel))
  end
  for _, rel in ipairs(without_name) do
    table.insert(decls, generate_child_rel_decl(rel))
  end
  return { name = sobject.name, fields = decls }
end

---@param decl table
---@return string
local function field_decl_to_string(decl)
  local comment_str = ""
  if decl.comment and decl.comment ~= "" then
    comment_str = INDENT .. "/* " .. decl.comment .. "\n" .. INDENT .. "*/\n"
  end
  return comment_str .. INDENT .. decl.modifier .. " " .. decl.type .. " " .. decl.name .. ";"
end

---@param definition table
---@return string
local function generate_faux_text(definition)
  local fields = {}
  for _, f in ipairs(definition.fields or {}) do
    table.insert(fields, f)
  end
  -- Deliberate deviation from VSCode: alphabetical sort by name.
  -- VSCode's comparator is provably broken (`first.name || first.type > second.name || second.type ? 1 : -1`).
  table.sort(fields, function(a, b)
    return (a.name or "") < (b.name or "")
  end)
  -- Dedup adjacent same-name entries, matching VSCode's post-sort filter.
  local deduped = {}
  for _, f in ipairs(fields) do
    local prev = deduped[#deduped]
    if not prev or prev.name ~= f.name then
      table.insert(deduped, f)
    end
  end
  local lines = {}
  for _, f in ipairs(deduped) do
    table.insert(lines, field_decl_to_string(f))
  end
  local class_decl = MODIFIER .. " class " .. definition.name .. " {\n"
  local constructor = INDENT .. MODIFIER .. " " .. definition.name .. " () \n" .. INDENT .. "{\n" .. INDENT .. "}\n"
  return HEADER .. class_decl .. table.concat(lines, "\n") .. "\n\n" .. constructor .. "}"
end

---@param name string
---@return boolean
local function required_sobject(name)
  if name:match("Share$") then
    return false
  end
  if name:match("History$") then
    return false
  end
  if name:match("Feed$") then
    return false
  end
  if name:match(".+Event$") then
    return false
  end
  return true
end

---@param sobject table
---@return boolean
local function is_custom(sobject)
  if sobject.custom ~= nil then
    return sobject.custom == true
  end
  local name = sobject.name or ""
  return name:match("__c$") ~= nil
    or name:match("__mdt$") ~= nil
    or name:match("__e$") ~= nil
    or name:match("__b$") ~= nil
    or name:match("__x$") ~= nil
end

---@param api_version string|number|nil
---@return string
local function format_api_version(api_version)
  if type(api_version) == "string" and api_version ~= "" then
    if api_version:sub(1, 1):lower() == "v" then
      return api_version
    end
    return "v" .. api_version
  end
  if type(api_version) == "number" then
    return string.format("v%.1f", api_version)
  end
  return "v60.0"
end

H._field_to_apex_type = function(field)
  if field.extraTypeInfo == "externallookup" then
    return "String"
  end
  return get_target_type(field.type or "")
end
H._generate_field_decls = generate_field_decls
H._generate_child_rel_decl = generate_child_rel_decl
H._generate_sobject_definition = generate_sobject_definition
H._generate_faux_text = generate_faux_text
H._required_sobject = required_sobject
H._is_custom = is_custom
H._sanitize_comment = sanitize_comment
H._strip_id = strip_id
H._format_api_version = format_api_version
H.TYPE_MAPPING = TYPE_MAPPING
H.HEADER = HEADER

Sobject.__test = H

---@param cmd string[]
---@param opts table|nil
---@param cb fun(obj: vim.SystemCompleted)
local function run(cmd, opts, cb)
  opts = opts or {}
  opts.text = true
  vim.system(cmd, opts, vim.schedule_wrap(cb))
end

---@param org string
---@param cb fun(info: table|nil, err: string|nil)
local function get_org_info(org, cb)
  run({ "sf", "org", "display", "-o", org, "--json" }, nil, function(obj)
    if obj.code ~= 0 then
      return cb(nil, "Failed to get org info. Is the org authenticated?")
    end
    local ok, parsed = pcall(vim.json.decode, obj.stdout)
    if not ok or type(parsed) ~= "table" or not parsed.result or not parsed.result.accessToken then
      return cb(nil, "Failed to parse org info.")
    end
    cb(parsed.result)
  end)
end

---@param org string
---@param cb fun(names: string[]|nil, err: string|nil)
local function list_sobjects(org, cb)
  run({ "sf", "sobject", "list", "-o", org, "-s", "ALL", "--json" }, nil, function(obj)
    if obj.code ~= 0 then
      return cb(nil, "sf sobject list failed (exit " .. obj.code .. ").")
    end
    local ok, parsed = pcall(vim.json.decode, obj.stdout)
    if not ok or type(parsed) ~= "table" or not parsed.result then
      return cb(nil, "Failed to parse sobject list response.")
    end
    cb(parsed.result)
  end)
end

---@param org_info table
---@param api_version string
---@param names string[]
---@param cb fun(describes: table[]|nil, err: string|nil, failed_count: integer|nil)
local function describe_batch(org_info, api_version, names, cb)
  local batch_requests = {}
  for _, n in ipairs(names) do
    table.insert(batch_requests, { method = "GET", url = api_version .. "/sobjects/" .. n .. "/describe" })
  end
  local body = vim.json.encode({ batchRequests = batch_requests })
  local endpoint = org_info.instanceUrl .. "/services/data/" .. api_version .. "/composite/batch"
  local cmd = {
    "curl",
    "-s",
    "-S",
    "-f",
    "-X",
    "POST",
    endpoint,
    "-H",
    "Authorization: Bearer " .. org_info.accessToken,
    "-H",
    "Content-Type: application/json",
    "--data-binary",
    "@-",
  }
  run(cmd, { stdin = body }, function(obj)
    if obj.code ~= 0 then
      return cb(nil, "composite/batch curl failed (exit " .. obj.code .. "): " .. (obj.stderr or ""))
    end
    local ok, parsed = pcall(vim.json.decode, obj.stdout)
    if not ok or type(parsed) ~= "table" or not parsed.results then
      return cb(nil, "Failed to parse composite/batch response.")
    end
    local describes = {}
    local failed = 0
    for _, res in ipairs(parsed.results) do
      if res.statusCode == 200 and type(res.result) == "table" then
        table.insert(describes, res.result)
      else
        failed = failed + 1
      end
    end
    cb(describes, nil, failed > 0 and failed or nil)
  end)
end

---@param sobjects_dir string
---@param describe table
local function write_faux_class(sobjects_dir, describe)
  if not describe.name then
    return
  end
  local subdir = is_custom(describe) and "customObjects" or "standardObjects"
  local filepath = sobjects_dir .. "/" .. subdir .. "/" .. describe.name .. ".cls"
  local definition = generate_sobject_definition(describe)
  local text = generate_faux_text(definition)
  local f, err = io.open(filepath, "w")
  if not f then
    U.show_warn("Failed to write " .. filepath .. ": " .. (err or "unknown"))
    return
  end
  f:write(text)
  f:close()
end

local function restart_apex_ls()
  local clients = vim.lsp.get_clients({ name = "apex_ls" })
  if #clients == 0 then
    return
  end
  for _, client in ipairs(clients) do
    local config = client.config
    local attached = {}
    for bufnr, _ in pairs(client.attached_buffers or {}) do
      if vim.api.nvim_buf_is_valid(bufnr) then
        table.insert(attached, bufnr)
      end
    end
    client:stop()
    local new_id = vim.lsp.start(config, { attach = false })
    if new_id then
      for _, b in ipairs(attached) do
        vim.lsp.buf_attach_client(b, new_id)
      end
    end
  end
end

---@param opts table|nil
function Sobject.refresh(opts)
  opts = opts or {}
  U.is_sf_cmd_installed()
  if vim.fn.executable("curl") ~= 1 then
    return U.show_err("curl is required for sObject refresh.")
  end

  local category = string.upper(opts.category or "ALL")
  if category ~= "ALL" and category ~= "STANDARD" and category ~= "CUSTOM" then
    return U.show_err("Invalid category: " .. category .. ". Use ALL, STANDARD, or CUSTOM.")
  end

  local org = opts.org
  if not org or org == "" then
    if U.is_empty_str(U.target_org) then
      return U.show_warn("No target org set. Run `:SF org setTarget` first.")
    end
    org = U.target_org
  end

  local ok, project_root = pcall(U.get_sf_root)
  if not ok or not project_root then
    return U.show_warn("Not in a sf project folder. Open a file under `sfdx-project.json` or `.forceignore`.")
  end
  if project_root:sub(-1) == "/" then
    project_root = project_root:sub(1, -2)
  end

  local sobjects_dir = project_root .. "/.sfdx/tools/sobjects"
  local standard_dir = sobjects_dir .. "/standardObjects"
  local custom_dir = sobjects_dir .. "/customObjects"

  U.show("Refreshing sObject definitions...")
  get_org_info(org, function(org_info, err)
    if err or not org_info then
      return U.show_err(err or "Org info missing.")
    end

    local api_version = format_api_version(org_info.apiVersion)
    list_sobjects(org, function(sobject_entries, list_err)
      if list_err then
        return U.show_err("SObject list error: " .. list_err)
      end
      if not sobject_entries or #sobject_entries == 0 then
        return U.show_warn("No sObjects found in org.")
      end

      -- The sf CLI returns a list of names (strings). We don't get the
      -- custom flag here, so categorization comes from the per-object
      -- describe.custom flag downstream. For STANDARD/CUSTOM category
      -- filtering we use the name suffix heuristic just to skip the
      -- describe call; the describe result is still the source of truth
      -- for which subdir to write into.
      local names = {}
      for _, entry in ipairs(sobject_entries) do
        local name = type(entry) == "string" and entry or entry.name
        if type(name) == "string" then
          local custom = is_custom({ name = name })
          local include = true
          if category == "CUSTOM" and not custom then
            include = false
          elseif category == "STANDARD" and custom then
            include = false
          end
          if include and required_sobject(name) then
            table.insert(names, name)
          end
        end
      end

      if #names == 0 then
        return U.show_warn("No sObjects matched category " .. category .. ".")
      end

      if category ~= "CUSTOM" then
        vim.fn.delete(standard_dir, "rf")
        vim.fn.mkdir(standard_dir, "p")
      end
      if category ~= "STANDARD" then
        vim.fn.delete(custom_dir, "rf")
        vim.fn.mkdir(custom_dir, "p")
      end

      local batches = {}
      for i = 1, #names, BATCH_SIZE do
        local batch = {}
        for j = i, math.min(i + BATCH_SIZE - 1, #names) do
          table.insert(batch, names[j])
        end
        table.insert(batches, batch)
      end

      local completed = 0
      local in_flight = 0
      local next_batch = 1
      local errors = 0
      local batch_errors = {}

      local on_done = function()
        if errors > 0 then
          U.show_warn(
            string.format(
              "sObject refresh finished with %d batch error(s): %s",
              errors,
              table.concat(batch_errors, "; ")
            )
          )
        else
          U.show(string.format("sObject definitions refreshed (%d objects).", completed))
        end
        if opts.restart_lsp ~= false then
          restart_apex_ls()
        end
        if type(opts.on_done) == "function" then
          opts.on_done(sobjects_dir)
        end
      end

      local launch_next
      launch_next = function()
        while in_flight < BATCH_CONCURRENCY and next_batch <= #batches do
          local idx = next_batch
          next_batch = next_batch + 1
          in_flight = in_flight + 1
          describe_batch(org_info, api_version, batches[idx], function(describes, batch_err, failed_count)
            in_flight = in_flight - 1
            if batch_err then
              errors = errors + 1
              table.insert(batch_errors, "batch " .. idx .. ": " .. batch_err)
            else
              if failed_count then
                errors = errors + failed_count
                table.insert(batch_errors, failed_count .. " item(s) in batch " .. idx .. " failed")
              end
              if describes then
                for _, desc in ipairs(describes) do
                  write_faux_class(sobjects_dir, desc)
                end
                completed = completed + #describes
              end
            end
            if next_batch <= #batches then
              launch_next()
            elseif in_flight == 0 then
              on_done()
            end
          end)
        end
      end
      launch_next()
    end)
  end)
end

return Sobject
