![Image](https://github.com/xixiaofinland/sf.nvim/assets/13655323/454d4a3d-d455-43f6-b44b-506862106b66)
<p align="center">
<img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=fff&style=for-the-badge" alt="Neovim" />
<img src="https://img.shields.io/badge/Made%20With%20Lua-2C2D72?logo=lua&logoColor=fff&style=for-the-badge" alt="made with lua" >
</p>
<h1 align="center">Sf.nvim</h1>
<p align="center">📸 Offer common functionalities for Salesforce development</p>

## ✨ Features

- 🔥 Push, retrieve, and create metadata files
- 💻 Integrated scratch terminal for on-the-fly commands
- 😎 Diff files between local and org environments
- 🤩 Display target org in the status line
- 👏 Access to a pre-downloaded list of metadata files
- 🤖 Facilitate quick Apex test runs

<br>

## 🎦 Video Intro (6 mins)

[![Feature Intro (6 min)](https://img.youtube.com/vi/MdqPgHIb1pw/0.jpg)](https://www.youtube.com/watch?v=MdqPgHIb1pw)

<br>

## 📝 Prerequisites

- 🌐 [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- 📦 Nvim-treesitter with the Apex parser installed (ensure_installed = { "apex", "soql", "sosl" }), e.g., [in my settings](https://github.com/xixiaofinland/dotfiles/blob/main/.config/nvim/lua/plugins/nvim-tree-sitter.lua)
- 🔍 (Optional) fzf-lua plugin for executing `SFListMdToRetrieve()` and `SFListMdTypeToRetrieve()`

<br>

## ⚙️  Installation

Install using Lazy.nvim by adding the following configuration to your setup:

```lua
return {
  'xixiaofinland/sf.nvim',
  branch = 'dev', -- use `main` if you want the more stable version

  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'ibhagwan/fzf-lua', -- no need if you don't use listing metadata feature
  },

  config = function()
    require('sf').setup()  -- Important to call setup() to initialize the plugin!
  end
}
```

🚨 **Notice:**

The hotkeys and user commands are **ONLY** enabled in a sf project
folder (i.e. has `.forceignore` or `sfdx-project.json` in the root path).

Run `:lua require'sf.util'.get_sf_root()` to verify if the current opened file
resides in sf project folder or not.

<br>

## 🛠️ Configuration

Custom configuration can be passed into `setup()` Below are the default
settings:

```lua
require('sf').setup({
  -- Unless you want to customize, no need to copy-paste any of these
  -- They are applied automatically

  -- This plugin has both hotkeys and user commands supplied
  -- This flag enable/disable hotkeys while user commands are always enabled
  enable_hotkeys = true,

  -- Metadata related hotkeys (e.g. push/retrieve Apex) are only enabled in
  -- these filetypes
  hotkeys_in_filetypes = {
    "apex", "sosl", "soql", "javascript", "html"
  },

  -- Define what metadata to be listed in `list_md_to_retrieve()` (<leader>ml)
  types_to_retrieve = {
    "ApexClass",
    "ApexTrigger",
    "StaticResource",
    "LightningComponentBundle"
  },
})
```

<br>

## 🎯 Display target_org

Upon starting Nvim, Sf.nvim executes `SfFetchOrgList` to fetch and save
authenticated org names. Display the target_org in your status line to
facilitate command execution against the target org.

Example configuration using lualine.nvim with target_org(`xixiao100`):

```lua
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.get_target_org()",
      } },
```
![Image 012](https://github.com/xixiaofinland/sf.nvim/assets/13655323/645a6625-aec6-4593-931e-84534ad3ac4c)

<br>

## 🔑 Keys

This plugin supplies both default hotkeys and user commands.
Default hotkeys can be disabled in Configuration by setting *enable_hotkeys* to `false`.

### 📈 Often used keys

| Default key       | function name           |   User command     | Explain           |
| ----------| ------------------| ----------| ------------------|
| `<leader>ss`     | set_target_org           |SFSetTargetOrg      | set target_org |
| `<leader>sf`     | fetch_org_list              |SFFetchOrgList|fetch/refresh orgs info|
| `<leader><leader>`     |toggle_term|SFToggle|terminal toggle|
| `<leader>sp`     |save_and_push|SFSaveAndPush|push current file|
| `<leader>sr`     |retrieve|SFRetrieve|retrieve current file|
| `<leader>ta`     |run_all_tests_in_this_file|SFRunAllTestsInThisFile|run all Apex tests in current file|
| `<leader>tt`     |run_current_test|SFRunCurrentTest|test this under cursor|
| `<leader>tr`     |repeat_last_tests|SFRunCurrentTest|repeat the last test|
| `<leader>to`     |open_test_select|SFOpenTestSelect|open a buffer to select tests|

All keys are listed in `:h sf.nvim` or [help.txt file](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt).

Example:

- If you have [which-key](https://github.com/folke/which-key.nvim) or a similar plugin installed, pressing `<leader>s` will hint to you what keys are enabled as
  shown in the screenshot below. Remember that default hotkeys are enabled only inside a sf folder.
![Image 003](https://github.com/xixiaofinland/sf.nvim/assets/13655323/85faa8cb-b1df-40dd-a1bf-323f94bbf13c)

Type `:SF` in Ex mode will list all user commands:
![Image 002](https://github.com/xixiaofinland/sf.nvim/assets/13655323/056648c5-5f4f-4385-9cc5-ab2ef2ad96f6)

<br>

### 💡 Custom hotkeys

What if the default keys don't meet your requirements?

You can pass any shell command into `run()` method to execute it in the integrated
terminal. For instance, `require('sf').run('ls -la')`, then define it as your key: `vim.keymap.set('n', '<leader>sk', require('sf').run('ls -la'), { noremap = true, silent = true, desc = 'run ls -la in the terminal' })`.

<br>

## 📚 Full Document

Checking all features via `:h sf.nvim` or [help.txt file](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt).

<br>

## 🚀 Feature: List/retrieve metadata and metadata types

Sometimes you don't know what metadata the target org contains, and you want to
list them and fetch specific ones.

1. Retrieve the metadata data by running the user command `SFPullMd`.
2. Run `SFListMdToRetrieve` (or `require('sf').list_md_to_retrieve()`) to show
   the list in a pop-up (requires the fzf-lua plugin) and select one to
   download to local.

Sometimes you want to fetch all files of a certain metadata type (Apex class,
LWC, Aura, etc.). You can list them and fetch all of a specific type.

1. Retrieve the metadata types by running the user command `SFPullMdType`.
2. Run `SFListMdTypeToRetrieve` (or `require('sf').list_md_type_to_retrieve()`) to show the
   list in a pop-up (requires the fzf-lua plugin) and select one to
   download all metadata of this type to local.

<br>

## ⚡Apex Test

You can,

- Run all tests in the current file by `<leader>ta`
- Run the test under the cursor by `<leader>tt`
- Select tests from the current file by `<leader>to`
- Re-run the last test command `<leader>tr`

(check the Key section for their corresponding keys and user commands if needed)

## 🖥️ Integrated terminal

The integrated terminal is designed to

- accept input from hotkeys and user commands, such as "retrieve current metadata"
  `<leader>sr`
- be a read-only buffer. It's, by design, not allowed to manually type commands e
- be disposable. The output text of the previous command is removed when a new command is invoked
- be auto-prompt, in case the terminal is hidden at the moment the command execution completes. This is handy when you have a long-running command.

You can pass any shell command into `run()` method to execute it in the integrated
terminal. For instance, `require('sf').run('ls -la')`.

<br>

## 🏆 Contributions

Please create an issue to discuss your PR before submitting it. This ensures
that the PR will be merged.

The PR must be submitted against the `dev` branch.

The `help.txt` file is auto-generated from the comments with the `---` suffix
before each function in `init.lua` (have a look at its existing format). The plugin
uses `mini.doc` to automatically generate `help.txt` from `init.lua`. Therefore,
updating `init.lua` without modifying `help.txt` is sufficient.

<br>

### 🤝 Contributors

Thanks to the following people for contributing to this project:

- ![GitHub Profile Image](https://github.com/FedeAbella.png?size=50) [@FedeAbella](https://github.com/FedeAbella)
- ![GitHub Profile Image](https://github.com/waltonzt.png?size=50) [@waltonzt](https://github.com/waltonzt)

<br>

## 📜 License
MIT.
