local U = require("sf.util")

local Sobject = {}
local H = {}

local BATCH_SIZE = 25
-- Each batch is its own `sf` process (Node start-up plus an auth refresh), so
-- far fewer run at once than the plain HTTP requests this replaced.
local BATCH_CONCURRENCY = 4
local MAX_NAMES_SHOWN = 10
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
    if not ok or type(parsed) ~= "table" or type(parsed.result) ~= "table" then
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

---@param s string|nil
---@return string
local function first_line(s)
  return vim.trim(vim.split(s or "", "\n", { plain = true })[1] or "")
end

-- Why a failed `sf api request rest --json` call failed, from its parsed
-- output: the HTTP status and Salesforce's message, or the CLI's own error.
---@param obj vim.SystemCompleted
---@param parsed table|nil
---@return string
local function describe_failure(obj, parsed)
  local response = parsed and parsed.result
  if type(response) == "table" and response.statusCode then
    local body = response.body
    local detail = type(body) == "table" and type(body[1]) == "table" and body[1].message
    return "HTTP " .. response.statusCode .. (type(detail) == "string" and (": " .. detail) or "")
  end
  local message = parsed and type(parsed.message) == "string" and parsed.message or first_line(obj.stderr)
  return "sf exited with " .. obj.code .. (message ~= "" and (": " .. message) or "")
end

-- Describes `names` in one composite/batch request. The sf CLI sends it, so
-- it authenticates (and refreshes the session) the way every other sf command
-- does, and the access token never appears on a command line.
---@param org string
---@param api_version string
---@param names string[]
---@param cb fun(describes: table[]|nil, err: string|nil, failed_names: string[]|nil)
local function describe_batch(org, api_version, names, cb)
  local batch_requests = {}
  for _, n in ipairs(names) do
    table.insert(batch_requests, { method = "GET", url = api_version .. "/sobjects/" .. n .. "/describe" })
  end
  -- A file rather than `--body -`: oclif gives up reading stdin after 10ms.
  local body_file = vim.fn.tempname() .. ".json"
  local ok_write = pcall(vim.fn.writefile, { vim.json.encode({ batchRequests = batch_requests }) }, body_file)
  if not ok_write then
    return vim.schedule(function()
      cb(nil, "could not write the request body to " .. body_file)
    end)
  end
  local cmd = {
    "sf",
    "api",
    "request",
    "rest",
    "services/data/" .. api_version .. "/composite/batch",
    "--method",
    "POST",
    "--body",
    "@" .. body_file,
    "-o",
    org,
    "--json",
  }
  run(cmd, nil, function(obj)
    vim.fn.delete(body_file)
    local ok, parsed = pcall(vim.json.decode, obj.stdout or "")
    parsed = ok and type(parsed) == "table" and parsed or nil
    local response = parsed and parsed.result
    if type(response) ~= "table" or response.statusCode ~= 200 then
      return cb(nil, describe_failure(obj, parsed))
    end
    local body = response.body
    if type(body) ~= "table" or type(body.results) ~= "table" then
      return cb(nil, "unexpected composite/batch response")
    end
    -- Sub-request results come back in request order.
    local describes = {}
    local failed_names = {}
    for i, name in ipairs(names) do
      local res = body.results[i]
      if type(res) == "table" and res.statusCode == 200 and type(res.result) == "table" then
        table.insert(describes, res.result)
      else
        table.insert(failed_names, name)
      end
    end
    cb(describes, nil, failed_names)
  end)
end

---@param sobjects_dir string
---@param describe table
---@return string|nil err
local function write_faux_class(sobjects_dir, describe)
  if not describe.name then
    return
  end
  local subdir = is_custom(describe) and "customObjects" or "standardObjects"
  local filepath = sobjects_dir .. "/" .. subdir .. "/" .. describe.name .. ".cls"
  -- An error thrown here would end the refresh without a word.
  local ok, text = pcall(function()
    return generate_faux_text(generate_sobject_definition(describe))
  end)
  if not ok then
    return "failed to generate " .. describe.name .. ": " .. tostring(text)
  end
  local f, err = io.open(filepath, "w")
  if not f then
    return "failed to write " .. filepath .. ": " .. (err or "unknown")
  end
  f:write(text)
  f:close()
end

-- Moves each refreshed subdir from `staging_dir` over its counterpart in
-- `sobjects_dir`. If any move fails, every subdir gets its previous version
-- back, so the definitions are either all new or all old.
---@param staging_dir string
---@param sobjects_dir string
---@param subdirs string[]
---@return boolean ok
---@return string|nil err
local function swap_in(staging_dir, sobjects_dir, subdirs)
  vim.fn.mkdir(sobjects_dir, "p")
  local swapped = {}
  local function roll_back()
    for i = #swapped, 1, -1 do
      local s = swapped[i]
      if s.moved_new then
        vim.uv.fs_rename(s.target, staging_dir .. "/" .. s.sub)
      end
      if s.had_old then
        vim.uv.fs_rename(s.backup, s.target)
      end
    end
  end
  for _, sub in ipairs(subdirs) do
    local s = {
      sub = sub,
      target = sobjects_dir .. "/" .. sub,
      backup = staging_dir .. "/" .. sub .. ".old",
    }
    s.had_old = vim.uv.fs_stat(s.target) ~= nil
    if s.had_old then
      local ok, err = vim.uv.fs_rename(s.target, s.backup)
      if not ok then
        roll_back()
        return false, err
      end
    end
    table.insert(swapped, s)
    local ok, err = vim.uv.fs_rename(staging_dir .. "/" .. sub, s.target)
    if not ok then
      roll_back()
      return false, err
    end
    s.moved_new = true
  end
  vim.fn.delete(staging_dir, "rf")
  return true
end

---@param names string[]
---@return string
local function format_names(names)
  if #names <= MAX_NAMES_SHOWN then
    return table.concat(names, ", ")
  end
  return table.concat(vim.list_slice(names, 1, MAX_NAMES_SHOWN), ", ") .. ", ..."
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

-- Set while a refresh runs: two at once would share the staging directory.
local refreshing = false

---@param opts table|nil
function Sobject.refresh(opts)
  opts = opts or {}
  U.is_sf_cmd_installed()

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

  if refreshing then
    return U.show_warn("An sObject refresh is already running.")
  end
  refreshing = true

  local sobjects_dir = project_root .. "/.sfdx/tools/sobjects"
  -- New definitions are written here and moved into sobjects_dir only once
  -- every describe batch has succeeded, so a failed refresh leaves the
  -- previous definitions in place. A sibling of sobjects_dir, so the move is a
  -- rename on the same filesystem and apex_ls never indexes half a refresh.
  local staging_dir = project_root .. "/.sfdx/tools/sobjects-refresh"

  ---@param notify fun(msg: string)
  ---@param msg string
  local finish = function(notify, msg)
    refreshing = false
    notify(msg)
  end

  -- Runs the async steps of this refresh. An error in one ends the refresh
  -- with a message instead of leaving `refreshing` set for the session, and
  -- makes the callbacks of batches still in flight do nothing.
  local aborted = false
  ---@param fn function
  ---@return function
  local guard = function(fn)
    return function(...)
      if aborted then
        return
      end
      local ok, err = pcall(fn, ...)
      if ok then
        return
      end
      if not refreshing then
        -- Already finished: the error came from apex_ls or opts.on_done.
        error(err, 0)
      end
      aborted = true
      pcall(vim.fn.delete, staging_dir, "rf")
      finish(U.show_err, "sObject refresh failed: " .. tostring(err) .. ". Kept the existing definitions.")
    end
  end

  U.show("Refreshing sObject definitions...")
  get_org_info(
    org,
    guard(function(org_info, err)
      if err or not org_info then
        return finish(U.show_err, err or "Org info missing.")
      end

      local api_version = format_api_version(org_info.apiVersion)
      list_sobjects(
        org,
        guard(function(sobject_entries, list_err)
          if list_err then
            return finish(U.show_err, "SObject list error: " .. list_err)
          end
          if not sobject_entries or #sobject_entries == 0 then
            return finish(U.show_warn, "No sObjects found in org.")
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
            return finish(U.show_warn, "No sObjects matched category " .. category .. ".")
          end

          -- Only the refreshed categories are swapped in, but both exist in
          -- staging so a describe whose custom flag disagrees with the name
          -- heuristic still has somewhere to be written.
          local subdirs = {}
          if category ~= "CUSTOM" then
            table.insert(subdirs, "standardObjects")
          end
          if category ~= "STANDARD" then
            table.insert(subdirs, "customObjects")
          end
          vim.fn.delete(staging_dir, "rf")
          vim.fn.mkdir(staging_dir .. "/standardObjects", "p")
          vim.fn.mkdir(staging_dir .. "/customObjects", "p")

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
          local batch_errors = {}
          local write_errors = {}
          local failed_names = {}

          local on_batches_done = function()
            if #batch_errors > 0 or #write_errors > 0 then
              vim.fn.delete(staging_dir, "rf")
              local reasons = {}
              if #batch_errors > 0 then
                table.insert(
                  reasons,
                  string.format(
                    "%d of %d describe batch(es) failed (%s)",
                    #batch_errors,
                    #batches,
                    table.concat(batch_errors, "; ")
                  )
                )
              end
              if #write_errors > 0 then
                table.insert(reasons, table.concat(write_errors, "; "))
              end
              return finish(
                U.show_err,
                "sObject refresh failed: " .. table.concat(reasons, "; ") .. ". Kept the existing definitions."
              )
            end

            -- An sObject the org listed but would not describe keeps its
            -- previous definition rather than disappearing.
            for _, name in ipairs(failed_names) do
              for _, sub in ipairs(subdirs) do
                local old = sobjects_dir .. "/" .. sub .. "/" .. name .. ".cls"
                local new = staging_dir .. "/" .. sub .. "/" .. name .. ".cls"
                if vim.uv.fs_stat(old) and not vim.uv.fs_stat(new) then
                  vim.uv.fs_copyfile(old, new)
                end
              end
            end

            local swapped, swap_err = swap_in(staging_dir, sobjects_dir, subdirs)
            if not swapped then
              return finish(
                U.show_err,
                string.format(
                  "sObject refresh failed to move the new definitions from %s into %s: %s",
                  staging_dir,
                  sobjects_dir,
                  swap_err or "unknown error"
                )
              )
            end

            if #failed_names > 0 then
              finish(
                U.show_warn,
                string.format(
                  "sObject definitions refreshed (%d objects); %d sObject(s) could not be described "
                    .. "and kept their previous definitions: %s",
                  completed,
                  #failed_names,
                  format_names(failed_names)
                )
              )
            else
              finish(U.show, string.format("sObject definitions refreshed (%d objects).", completed))
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
              describe_batch(
                org,
                api_version,
                batches[idx],
                guard(function(describes, batch_err, batch_failed_names)
                  in_flight = in_flight - 1
                  if batch_err then
                    table.insert(batch_errors, "batch " .. idx .. ": " .. batch_err)
                  else
                    vim.list_extend(failed_names, batch_failed_names or {})
                    for _, desc in ipairs(describes or {}) do
                      if desc.name then
                        local write_err = write_faux_class(staging_dir, desc)
                        if write_err then
                          table.insert(write_errors, write_err)
                        else
                          completed = completed + 1
                        end
                      end
                    end
                  end
                  if next_batch <= #batches then
                    launch_next()
                  elseif in_flight == 0 then
                    on_batches_done()
                  end
                end)
              )
            end
          end
          launch_next()
        end)
      )
    end)
  )
end

return Sobject
