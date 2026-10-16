local helpers = dofile("tests/helpers.lua")
local child = helpers.new_child_neovim()
local expect, eq = helpers.expect, helpers.expect.equality
local new_set = MiniTest.new_set

local T = new_set({
  hooks = {
    pre_case = function()
      child.setup()
      child.sf_setup()
      child.lua([[S = require('sf.sobject')]])
      child.lua([[H = S.__test]])
    end,
    post_once = child.stop,
  },
})

T["type_mapping"] = new_set()

T["type_mapping"]["maps known string-like types to String"] = function()
  for _, t in ipairs({
    "string",
    "email",
    "phone",
    "url",
    "picklist",
    "multipicklist",
    "textarea",
    "encryptedstring",
    "combobox",
  }) do
    eq(child.lua_get(string.format("H._field_to_apex_type({ type = %q })", t)), "String")
  end
end

T["type_mapping"]["maps id to Id"] = function()
  eq(child.lua_get('H._field_to_apex_type({ type = "id" })'), "Id")
end

T["type_mapping"]["maps numerics"] = function()
  eq(child.lua_get('H._field_to_apex_type({ type = "double" })'), "Double")
  eq(child.lua_get('H._field_to_apex_type({ type = "percent" })'), "Double")
  eq(child.lua_get('H._field_to_apex_type({ type = "int" })'), "Integer")
  eq(child.lua_get('H._field_to_apex_type({ type = "currency" })'), "Decimal")
end

T["type_mapping"]["maps anyType (camel case) to Object"] = function()
  eq(child.lua_get('H._field_to_apex_type({ type = "anyType" })'), "Object")
end

T["type_mapping"]["externallookup short-circuits to String"] = function()
  eq(child.lua_get('H._field_to_apex_type({ type = "reference", extraTypeInfo = "externallookup" })'), "String")
end

T["type_mapping"]["unknown type capitalizes"] = function()
  eq(child.lua_get('H._field_to_apex_type({ type = "json" })'), "Json")
end

T["generate_field_decls"] = new_set()

T["generate_field_decls"]["plain field emits one decl"] = function()
  local decls = child.lua_get('H._generate_field_decls({ name = "Name", type = "string" })')
  eq(#decls, 1)
  eq(decls[1].type, "String")
  eq(decls[1].name, "Name")
end

T["generate_field_decls"]["single-target reference emits relationship + Id"] = function()
  local decls = child.lua_get([[
    H._generate_field_decls({
      name = "AccountId",
      type = "reference",
      referenceTo = { "Account" },
      relationshipName = "Account",
    })
  ]])
  eq(#decls, 2)
  eq(decls[1].type, "Account")
  eq(decls[1].name, "Account")
  eq(decls[2].type, "Id")
  eq(decls[2].name, "AccountId")
end

T["generate_field_decls"]["polymorphic reference emits SObject + Id"] = function()
  local decls = child.lua_get([[
    H._generate_field_decls({
      name = "WhoId",
      type = "reference",
      referenceTo = { "Contact", "Lead" },
      relationshipName = "Who",
    })
  ]])
  eq(#decls, 2)
  eq(decls[1].type, "SObject")
  eq(decls[1].name, "Who")
  eq(decls[2].type, "Id")
  eq(decls[2].name, "WhoId")
end

T["generate_field_decls"]["missing relationshipName falls back to stripId"] = function()
  local decls = child.lua_get([[
    H._generate_field_decls({
      name = "ParentId",
      type = "reference",
      referenceTo = { "Parent__c" },
    })
  ]])
  eq(decls[1].name, "Parent")
end

T["generate_field_decls"]["externallookup emits String, no relationship line"] = function()
  local decls = child.lua_get([[
    H._generate_field_decls({
      name = "Ext__c",
      type = "reference",
      extraTypeInfo = "externallookup",
    })
  ]])
  eq(#decls, 1)
  eq(decls[1].type, "String")
end

T["sanitize_comment"] = new_set()

T["sanitize_comment"]["strips comment terminator patterns"] = function()
  eq(child.lua_get([[H._sanitize_comment("safe text")]]), "safe text")
  eq(child.lua_get([[H._sanitize_comment("dangerous */ payload")]]), "dangerous  payload")
  eq(child.lua_get([[H._sanitize_comment("nested /* hello */ ok")]]), "nested  hello  ok")
  eq(child.lua_get([[H._sanitize_comment("self /**/ closed")]]), "self  closed")
end

T["child_relationships"] = new_set()

T["child_relationships"]["with relationshipName uses it"] = function()
  local decl = child.lua_get([[
    H._generate_child_rel_decl({
      childSObject = "Case",
      field = "AccountId",
      relationshipName = "Cases",
    })
  ]])
  eq(decl.type, "List<Case>")
  eq(decl.name, "Cases")
end

T["child_relationships"]["without relationshipName strips Id suffix"] = function()
  local decl = child.lua_get([[
    H._generate_child_rel_decl({
      childSObject = "Task",
      field = "WhatId",
    })
  ]])
  eq(decl.name, "What")
end

T["required_sobject"] = new_set()

T["required_sobject"]["filters Share/History/Feed/<X>Event suffixes"] = function()
  eq(child.lua_get('H._required_sobject("AccountShare")'), false)
  eq(child.lua_get('H._required_sobject("AccountHistory")'), false)
  eq(child.lua_get('H._required_sobject("AccountFeed")'), false)
  eq(child.lua_get('H._required_sobject("MyEvent")'), false)
end

T["required_sobject"]["keeps everything else"] = function()
  eq(child.lua_get('H._required_sobject("Account")'), true)
  eq(child.lua_get('H._required_sobject("MyCustom__c")'), true)
  -- The .+Event$ regex requires at least one char before "Event", so "Event" itself stays.
  eq(child.lua_get('H._required_sobject("Event")'), true)
end

T["is_custom"] = new_set()

T["is_custom"]["trusts describe.custom when present"] = function()
  eq(child.lua_get('H._is_custom({ name = "Foo", custom = true })'), true)
  eq(child.lua_get('H._is_custom({ name = "Foo", custom = false })'), false)
end

T["is_custom"]["falls back to suffix pattern when missing"] = function()
  eq(child.lua_get('H._is_custom({ name = "Foo__c" })'), true)
  eq(child.lua_get('H._is_custom({ name = "Foo__mdt" })'), true)
  eq(child.lua_get('H._is_custom({ name = "Account" })'), false)
end

T["faux_text"] = new_set()

T["faux_text"]["produces a sorted, deduped, fully-formed class"] = function()
  local text = child.lua_get([[
    H._generate_faux_text({
      name = "Demo__c",
      fields = {
        { modifier = "global", type = "String", name = "Name" },
        { modifier = "global", type = "Id", name = "Id" },
        { modifier = "global", type = "Account", name = "Account" },
        { modifier = "global", type = "Id", name = "AccountId" },
        { modifier = "global", type = "Id", name = "AccountId" },  -- duplicate
      },
    })
  ]])
  expect.match(text, "global class Demo__c %{")
  expect.match(text, "global Account Account;")
  expect.match(text, "global Id AccountId;")
  expect.match(text, "global Id Id;")
  expect.match(text, "global String Name;")
  expect.match(text, "global Demo__c %(%) ")
  -- header is present
  expect.match(text, "// This file is generated as an Apex representation")
  -- duplicates collapsed
  local _, count = text:gsub("global Id AccountId;", "")
  eq(count, 1)
end

T["faux_text"]["fields sorted alphabetically by name"] = function()
  local text = child.lua_get([[
    H._generate_faux_text({
      name = "Demo__c",
      fields = {
        { modifier = "global", type = "String", name = "Z" },
        { modifier = "global", type = "String", name = "A" },
        { modifier = "global", type = "String", name = "M" },
      },
    })
  ]])
  local idx_a = text:find("global String A;")
  local idx_m = text:find("global String M;")
  local idx_z = text:find("global String Z;")
  eq(idx_a < idx_m, true)
  eq(idx_m < idx_z, true)
end

T["faux_text"]["emits inline help text as a comment block"] = function()
  local text = child.lua_get([[
    H._generate_faux_text({
      name = "Demo__c",
      fields = {
        { modifier = "global", type = "String", name = "F", comment = "help text" },
      },
    })
  ]])
  expect.match(text, "/%* help text\n    %*/\n    global String F;")
end

T["faux_text"]["inline help text is sanitized at the field-decl boundary"] = function()
  local decls = child.lua_get([[
    H._generate_field_decls({ name = "F", type = "string", inlineHelpText = "danger */ stripped" })
  ]])
  eq(decls[1].comment, "danger  stripped")
end

T["format_api_version"] = new_set()

T["format_api_version"]["passes through v-prefixed strings"] = function()
  eq(child.lua_get('H._format_api_version("v60.0")'), "v60.0")
end

T["format_api_version"]["adds v prefix when missing"] = function()
  eq(child.lua_get('H._format_api_version("60.0")'), "v60.0")
end

T["format_api_version"]["formats numbers"] = function()
  eq(child.lua_get("H._format_api_version(60)"), "v60.0")
end

T["format_api_version"]["falls back to v60.0 on nil"] = function()
  eq(child.lua_get("H._format_api_version(nil)"), "v60.0")
end

-- ── refresh, through the sf CLI fake

local DESCRIBE_CMD = "sf api request rest services/data/v62.0/composite/batch"

-- Makes the child's cwd a fresh sf project holding the definitions of an
-- earlier refresh, and counts apex_ls restarts in `_G.lsp_restarts`.
local function setup_refresh()
  child.capture_notify()
  child.lua([[
    local root = vim.fn.tempname()
    local sobjects = root .. "/.sfdx/tools/sobjects"
    vim.fn.mkdir(sobjects .. "/standardObjects", "p")
    vim.fn.mkdir(sobjects .. "/customObjects", "p")
    vim.fn.writefile({ "{}" }, root .. "/sfdx-project.json")
    vim.fn.writefile({ "// old Account" }, sobjects .. "/standardObjects/Account.cls")
    vim.fn.writefile({ "// old Contact" }, sobjects .. "/standardObjects/Contact.cls")
    vim.fn.writefile({ "// old Gone__c" }, sobjects .. "/customObjects/Gone__c.cls")
    vim.cmd.cd(root)
    _G.tools_dir = root .. "/.sfdx/tools"

    _G.lsp_restarts = 0
    vim.lsp.get_clients = function(filter)
      if filter and filter.name == "apex_ls" then
        _G.lsp_restarts = _G.lsp_restarts + 1
      end
      return {}
    end
  ]])
end

-- Every file under .sfdx/tools, as relative path -> content.
local function tools_files()
  return child.lua_get([[(function()
    local files = {}
    for path, type in vim.fs.dir(_G.tools_dir, { depth = 10 }) do
      if type == "file" then
        files[path] = table.concat(vim.fn.readfile(_G.tools_dir .. "/" .. path), "\n")
      end
    end
    return files
  end)()]])
end

local function refresh(opts)
  child.lua([[require('sf').refresh_sobjects(...)]], { opts or { org = "devhub" } })
  child.sf_fake.wait()
end

---@param level string "INFO"|"WARN"|"ERROR"
local function last_notified(level)
  local notified = child.notified()
  local last = notified[#notified]
  eq(last.level, child.lua_get("vim.log.levels." .. level))
  return last.msg
end

local OLD_FILES = {
  ["sobjects/standardObjects/Account.cls"] = "// old Account",
  ["sobjects/standardObjects/Contact.cls"] = "// old Contact",
  ["sobjects/customObjects/Gone__c.cls"] = "// old Gone__c",
}

-- The sObjects the recorded describe batch answers for, in its order; the
-- last one doesn't exist. The fake gives every batch that same answer, so the
-- org's real list of a thousand names would make thirty identical batches.
local LISTED = {
  cmd = "sf sobject list",
  stdout = vim.json.encode({ status = 0, result = { "Account", "Contact", "NoSuchObject__c" } }),
}

T["refresh"] = new_set({ hooks = { pre_case = setup_refresh } })

T["refresh"]["keeps existing definitions when the describes fail"] = function()
  child.sf_fake.install({
    { cmd = "sf org display", fixture = "org_display" },
    LISTED,
    { cmd = DESCRIBE_CMD, fixture = "api_request_rest_401" },
  })

  refresh()

  eq(tools_files(), OLD_FILES)
  local msg = last_notified("ERROR")
  expect.match(msg, "1 of 1 describe batch")
  expect.match(msg, "401")
  expect.match(msg, "Kept the existing definitions")
  eq(child.lua_get("_G.lsp_restarts"), 0)
end

T["refresh"]["reports an error on the way and still accepts the next refresh"] = function()
  child.sf_fake.install({
    { cmd = "sf org display", fixture = "org_display" },
    LISTED,
    { cmd = DESCRIBE_CMD, fixture = "api_request_rest_composite_batch" },
  })
  -- The staging directory can't be created in a read-only .sfdx/tools.
  child.lua([[vim.fn.setfperm(_G.tools_dir, "r-xr-xr-x")]])

  refresh()

  child.lua([[vim.fn.setfperm(_G.tools_dir, "rwxr-xr-x")]])
  eq(tools_files(), OLD_FILES)
  expect.match(last_notified("ERROR"), "^sObject refresh failed: ")
  eq(child.lua_get("_G.lsp_restarts"), 0)

  refresh()

  expect.match(last_notified("WARN"), "refreshed %(2 objects%)")
end

T["refresh"]["keeps existing definitions when some describe batches fail"] = function()
  -- 30 names make two batches of at most 25; the first one is rejected.
  local names = {}
  for i = 1, 30 do
    table.insert(names, string.format("Obj%02d__c", i))
  end
  child.sf_fake.install({
    { cmd = "sf org display", fixture = "org_display" },
    { cmd = "sf sobject list", stdout = vim.json.encode({ status = 0, result = names }) },
    { cmd = DESCRIBE_CMD, fixture = "api_request_rest_401", times = 1 },
    { cmd = DESCRIBE_CMD, fixture = "api_request_rest_composite_batch" },
  })

  refresh()

  eq(#child.sf_fake.cmds(), 4)
  eq(tools_files(), OLD_FILES)
  local msg = last_notified("ERROR")
  expect.match(msg, "1 of 2 describe batch")
  expect.match(msg, "batch 1: HTTP 401: Session expired or invalid")
  eq(child.lua_get("_G.lsp_restarts"), 0)
end

T["refresh"]["describes through sf without the access token on any command line"] = function()
  child.sf_fake.install({
    { cmd = "sf org display", fixture = "org_display" },
    { cmd = "sf sobject list", fixture = "sobject_list" },
    { cmd = DESCRIBE_CMD, fixture = "api_request_rest_composite_batch" },
  })

  refresh()

  local cmds = child.sf_fake.cmds()
  eq(cmds[1], "sf org display -o devhub --json")
  eq(cmds[2], "sf sobject list -o devhub -s ALL --json")
  -- A real org lists far more than one batch of 25 sObjects.
  expect.equality(#cmds > 3, true)
  for i = 3, #cmds do
    expect.match(
      cmds[i],
      "^sf api request rest services/data/v62%.0/composite/batch %-%-method POST %-%-body @.+ %-o devhub %-%-json$"
    )
  end
  for _, cmd in ipairs(cmds) do
    expect.no_match(cmd, "FAKE_ACCESS_TOKEN")
  end
end

T["refresh"]["swaps in new definitions, keeping the old one of an sObject that failed to describe"] = function()
  child.lua(
    [[vim.fn.writefile({ "// old NoSuchObject__c" }, _G.tools_dir .. "/sobjects/customObjects/NoSuchObject__c.cls")]]
  )
  child.sf_fake.install({
    { cmd = "sf org display", fixture = "org_display" },
    LISTED,
    { cmd = DESCRIBE_CMD, fixture = "api_request_rest_composite_batch" },
  })

  refresh()

  local files = tools_files()
  local paths = vim.tbl_keys(files)
  table.sort(paths)
  eq(paths, {
    "sobjects/customObjects/NoSuchObject__c.cls",
    "sobjects/standardObjects/Account.cls",
    "sobjects/standardObjects/Contact.cls",
  })
  expect.match(files["sobjects/standardObjects/Account.cls"], "global class Account {")
  expect.match(files["sobjects/standardObjects/Contact.cls"], "global class Contact {")
  -- The org listed NoSuchObject__c but its describe failed.
  eq(files["sobjects/customObjects/NoSuchObject__c.cls"], "// old NoSuchObject__c")

  local msg = last_notified("WARN")
  expect.match(msg, "refreshed %(2 objects%)")
  expect.match(msg, "1 sObject%(s%) could not be described")
  expect.match(msg, "NoSuchObject__c")
  eq(child.lua_get("_G.lsp_restarts"), 1)
end

return T
