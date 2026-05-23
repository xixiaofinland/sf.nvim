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
  for _, t in ipairs({ "string", "email", "phone", "url", "picklist", "multipicklist", "textarea", "encryptedstring", "combobox" }) do
    eq(child.lua_get(string.format('H._field_to_apex_type({ type = %q })', t)), "String")
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
  eq(child.lua_get('H._format_api_version(60)'), "v60.0")
end

T["format_api_version"]["falls back to v60.0 on nil"] = function()
  eq(child.lua_get('H._format_api_version(nil)'), "v60.0")
end

return T
