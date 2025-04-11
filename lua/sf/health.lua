local M = {}
local H = {}

M.check = function()
  H.check_nvim_version()
  H.check_sf_cli()
  H.check_tree_sitter()
  H.check_fzf_lua()
  H.check_ctag()
  H.check_overseer()
  H.check_windows_os()
end

-- helper;

H.check_sf_cli = function()
  if vim.fn.executable("sf") ~= 1 then
    return vim.health.error("sf cli not found!")
  end

  vim.health.ok("sf cli found.")
end

H.check_tree_sitter = function()
  if not pcall(require, "nvim-treesitter") then
    return vim.health.error("nvim-treesitter plugin not found!")
  end
  vim.health.ok("nvim-treesitter plugin found.")

  local parsers = require("nvim-treesitter.parsers").get_parser_configs()
  if parsers["apex"] == nil then
    return vim.health.error("apex parser not installed in nvim-treesitter!")
  end
  if parsers["soql"] == nil then
    return vim.health.error("soql parser not installed in nvim-treesitter!")
  end
  if parsers["sosl"] == nil then
    return vim.health.error("sosl parser not installed in nvim-treesitter!")
  end
  if parsers["sflog"] == nil then
    return vim.health.error("sflog parser not installed in nvim-treesitter!")
  end
  vim.health.ok("All Salesforce relevant parsers are installed in nvim-treesitter.")
end

H.check_nvim_version = function()
  local v = vim.version()
  local v_in_str = string.format("v%s.%s", v.major, v.minor)

  if v.major == 0 and v.minor < 10 then
    return vim.health.error("installed Nvim version: " .. v_in_str .. ", plugin demands 0.10 or higher!")
  else
    vim.health.ok("nvim version ok: " .. v_in_str)
  end
end

H.check_fzf_lua = function()
  if not pcall(require, "fzf-lua") then
    return vim.health.warn(
      "Optional: fzf-lua not found. Some features for listing items won't work. You could install `ibhagwan/fzf-lua`."
    )
  end
  vim.health.ok("fzf-lua plugin found.")
end

H.check_ctag = function()
  if vim.fn.executable("ctags") ~= 1 then
    return vim.health.warn(
      "Optional: ctags command not found in the path. Enhanced apex jump-to-definition won't work. You could install `universal ctags`."
    )
  end

  vim.health.ok("ctags command found.")
end

H.check_overseer = function()
  if not pcall(require, "overseer") then
    return vim.health.warn("Optional: overseer not found. ")
  end
  vim.health.ok("overseer plugin found.")
end

H.check_windows_os = function()
  if vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1 then
    return vim.health.warn("Windows OS detected. Functionality not guaranteed.")
  end
end

return M
