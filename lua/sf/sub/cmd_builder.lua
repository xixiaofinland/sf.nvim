local U = require('sf.util')

---@class CommandBuilder
---@field base_cmd string
---@field command string
---@field action string
---@field subactions table<string>
---@field params table<string, string>
---@field param_str string
---@field org string|nil
local CommandBuilder = {}
CommandBuilder.__index = CommandBuilder

---Create a new CommandBuilder instance
---@param base_command string|nil
---@return CommandBuilder
function CommandBuilder:new(base_command)
    local obj = setmetatable({
        base_cmd = base_command or "sf",
        command = "",
        action = "",
        subactions = {},
        params = {},
        param_str = "",
        org = U.target_org or nil,
        require_org = true,
    }, CommandBuilder)
    return obj
end

---Set the command
---@param cmd string
---@return CommandBuilder
function CommandBuilder:cmd(cmd)
    self.command = cmd
    return self
end

---Set the action
---@param action string
---@return CommandBuilder
function CommandBuilder:act(action)
    self.action = action
    return self
end

---Add a sub-action
---@param subaction string
---@return CommandBuilder
function CommandBuilder:subact(subaction)
    table.insert(self.subactions, subaction)
    return self
end

---Make the command local only
---@return CommandBuilder
function CommandBuilder:localOnly()
    self.require_org = false
    return self
end

---Add one or more parameters
---@param ... string|table Either a flag and value as separate arguments, or a table of flag-value pairs
---@return CommandBuilder
function CommandBuilder:addParams(...)
    local args = { ... }
    if type(args[1]) == "table" then
        -- If a table is passed, assume it's a list of flag-value pairs
        for flag, value in pairs(args[1]) do
            self.params[flag] = value
        end
    else
        -- If individual arguments are passed, assume it's a single flag-value pair
        local flag, value = args[1], args[2] or ''
        self.params[flag] = value
    end
    return self
end

---Set the param str. When params are given as string or the flag is the same for multiple params
---@param param_str string
---@return CommandBuilder
function CommandBuilder:addParamStr(param_str)
    self.param_str = param_str
    return self
end

---Set the org property
---@param org string
---@return CommandBuilder
function CommandBuilder:set_org(org)
    self.org = org
    return self
end

---Validate the command
function CommandBuilder:validate()
    local required_fields = {
        { field = "command", message = '"command" property not set' },
        { field = "action",  message = '"action" property not set' },
        { field = "org",     message = 'no given org value nor default target_org' }
    }

    for _, field in ipairs(required_fields) do
        if U.is_empty_str(self[field.field]) then
            U.notify_then_error('Invalid cmd building: ' .. field.message)
        end
    end
end

---Sort the params based on the specified rules
---@return table<integer, {flag: string, value: string}>
function CommandBuilder:sortParams()
    local paramsWithValue = {}
    local paramsWithoutValue = {}

    for flag, value in pairs(self.params) do
        if value ~= "" then
            table.insert(paramsWithValue, { flag = flag, value = value })
        else
            table.insert(paramsWithoutValue, { flag = flag, value = value })
        end
    end

    table.sort(paramsWithValue, function(a, b) return a.flag < b.flag end)
    table.sort(paramsWithoutValue, function(a, b) return a.flag < b.flag end)

    for _, param in ipairs(paramsWithoutValue) do
        table.insert(paramsWithValue, param)
    end

    return paramsWithValue
end

---Build the final command string
---@return string
function CommandBuilder:build()
    self:validate()

    local cmd = string.format('%s %s %s',
        self.base_cmd, self.command, self.action)

    if #self.subactions > 0 then
        local subact_string = ""
        for _, subaction in ipairs(self.subactions) do
            subact_string = subact_string .. " " .. subaction
        end

        if subact_string ~= "" then
            cmd = cmd .. " " .. subact_string
        end
    end

    local sortedParams = self:sortParams()
    if #sortedParams > 0 then
        local param_strings = {}
        for _, param in ipairs(sortedParams) do
            if param.value == "" then
                table.insert(param_strings, param.flag)
            else
                local expanded_value = string.format('"%s"', vim.fn.expandcmd(param.value))
                table.insert(param_strings, param.flag .. " " .. expanded_value)
            end
        end
        cmd = cmd .. " " .. table.concat(param_strings, " ")
    end

    if not U.is_empty_str(self.param_str) then
        cmd = cmd .. ' ' .. self.param_str
    end

    if self.require_org then
      local org_param = string.format('-o "%s"', self.org)
      cmd = cmd .. " " .. org_param
    end

    return cmd
end

---Build the final command as a string table
---@return table
function CommandBuilder:buildAsTable()
    self:validate()

    local cmd_tbl = {self.base_cmd, self.command, self.action}

    if #self.subactions > 0 then
        for _, subaction in ipairs(self.subactions) do
            table.insert(cmd_tbl, subaction)
        end
    end

    local sortedParams = self:sortParams()
    if #sortedParams > 0 then
        for _, param in ipairs(sortedParams) do
            table.insert(cmd_tbl, param.flag)
            if param.value ~= "" then
                local expanded_value = string.format('%s', vim.fn.expandcmd(param.value))
                table.insert(cmd_tbl, expanded_value)
            end
        end
    end

    if self.require_org then
      table.insert(cmd_tbl, '-o')
      table.insert(cmd_tbl, self.org)
    end

    return cmd_tbl
end

function CommandBuilder:t()
    local t = "%:p"
    return vim.fn.expandcmd(t)
end

return CommandBuilder
