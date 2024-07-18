![Image](https://github.com/xixiaofinland/sf.nvim/assets/13655323/454d4a3d-d455-43f6-b44b-506862106b66)
<p align="center">
<img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=fff&style=for-the-badge" alt="Neovim" />
<img src="https://img.shields.io/badge/Made%20With%20Lua-2C2D72?logo=lua&logoColor=fff&style=for-the-badge" alt="made with lua" >
</p>
<h1 align="center">Sf.nvim</h1>
<p align="center">📸 Offer common functionalities for Salesforce development</p>

# 📖 Table of Content

- [Features](#-features)
- [Intro video](#-intro-video-6min)
- [Prerequisites](#-prerequisites)
- [Installation](#%EF%B8%8F--installation)
- [Configuration](#%EF%B8%8F-configuration)
- [Display target org](#-display-target_org)
- [Keys](#-keys)
- [Full doc](#-full-document)
- [List/retrieve metadata](#-feature-listretrieve-metadata-and-metadata-types)
- [Apex test](#apex-test)
- [Integrated term](#%EF%B8%8F-integrated-terminal)
- [Apex jump](#-enhanced-jump-to-definition-apex)
- [Contributions](#-contributions)

## ✨ Features

- 🔥 Apex/Lwc/Aura: push, retrieve, create
- 💻 Integrated term
- 😎 File diff: local v.s. org
- 🤩 Target-org icon
- 👏 Org Metadata browsing
- 🤖 Quick apex test run
- ✨ Test report and code coverage info
- 🦘 Enhanced jump-to-definition (Apex)

<br>

## 🎦 Intro video (6min)

[![Feature Intro (6 min)](https://img.youtube.com/vi/MdqPgHIb1pw/0.jpg)](https://www.youtube.com/watch?v=MdqPgHIb1pw)

<br>

## 📝 Prerequisites

- 🌐 [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- 🐢 Nvim v0.10 or newer ([why must > 0.10?](https://github.com/xixiaofinland/sf.nvim/issues/73))
- 📦 Nvim-treesitter with the Apex parser installed (ensure_installed = { "apex", "soql", "sosl" }), e.g., [in my settings](https://github.com/xixiaofinland/dotfiles/blob/main/.config/nvim/lua/plugins/nvim-tree-sitter.lua)
- 🔍 (Optional) fzf-lua plugin for executing `SFListMdToRetrieve()` and `SFListMdTypeToRetrieve()`
  (Why not telescope.nvim? Because its UI is slow)

<br>

## ⚙️  Installation

Install using Lazy.nvim by adding the following configuration to your setup:

```lua
return {
  'xixiaofinland/sf.nvim',

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

  -- Some hotkeys are on "project level" thus always enabled. Examples: "set default org", "fetch org info".
  -- Other hotkeys are enabled when only metadata filetypes are loaded in the current buffer. Example: "push/retrieve current metadata file"
  -- This list defines what metadata filetypes have the "other hotkeys" enabled.
  -- For example, if you want to push/retrieve css files, it needs to be added into this list.
  hotkeys_in_filetypes = {
    "apex", "sosl", "soql", "javascript", "html"
  },

  -- Define what metadata to be listed in `list_md_to_retrieve()` (<leader>ml)
  -- Salesforce has numerous metadata types. We narrow down the scope of `list_md_to_retrieve()`.
  types_to_retrieve = {
    "ApexClass",
    "ApexTrigger",
    "StaticResource",
    "LightningComponentBundle"
  },

  -- Configuration for the integrated terminal
  term_config = {
    blend = 10,     -- background transparency: 0 is fully opaque; 100 is fully transparent
    dimensions = {
      height = 0.4, --proportional of the editor height. 0.4 means 40%.
      width = 0.8,  -- proportional of the editor width. 0.8 means 80%.
      x = 0.5,      -- starting position of width. Details in `get_dimension()` in raw_term.lua source code.
      y = 0.9,      -- starting position of height. Details in `get_dimension()` in raw_term.lua source code.
    },
  },

  -- the sf project metadata folder, update this in case you diverged from the default sf folder structure
  default_dir = '/force-app/main/default/',

  -- the folder this plugin uses to store intermediate data. It's under the sf project root directory.
  plugin_folder_name = '/sf_cache/',

  -- after the test running with code coverage completes, display uncovered line sign automatically.
  -- you can set it to `false`, then manually run toggle_sign command.
  auto_display_code_sign = true,

  -- code coverage sign icon colors
  code_sign_highlight = {
    covered = { fg = "#B7F071" }, -- set `fg = ""` to disable this sign icon
    uncovered = { fg = "#F07178" }, -- set `fg = ""` to disable this sign icon
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
| `<leader>ct`     |create_ctags |SFCreateCtags|create ctags file|
| `<leader>sq`     | run_highlighted_soql |N/A|Deault key is only enabled in visual model. Highlight selected text will be run as SOQL in the term|
|`\s`|toggle_sign |N/A|Show/hide line coverage sign icon|
|`]v`|uncovered_jump_forward |N/A|jump to next test uncovered hunk|
|`[v`|`uncovered_jump_backward |N/A|jump to last test uncovered hunk|

All keys are listed in `:h sf.nvim` or [help.txt file](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt).

Example:

- If you have [which-key](https://github.com/folke/which-key.nvim) or a similar plugin installed, pressing `<leader>s` will hint to you what keys are enabled as
  shown in the screenshot below. Remember that default hotkeys are enabled only inside a sf folder.
![Image 003](https://github.com/xixiaofinland/sf.nvim/assets/13655323/85faa8cb-b1df-40dd-a1bf-323f94bbf13c)

Type `:SF` in Ex mode will list all user commands:
![Screenshot 2024-07-17 at 9 43 07](https://github.com/user-attachments/assets/3cb2f4e9-2ac4-4a9c-825c-a94240f97e66)

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
list them and fetch specific ones. Steps:

1. Retrieve the metadata data by running the user command `SFPullMd`.
2. Run `SFListMdToRetrieve` (or `require('sf').list_md_to_retrieve()`) to show
   the list in a pop-up (requires the fzf-lua plugin) and select one to
   download to local.

Sometimes you want to fetch all files of a certain metadata type (Apex class,
LWC, Aura, etc.). You can list them and fetch all of a specific type. Steps:

1. Retrieve the metadata types by running the user command `SFPullMdType`.
2. Run `SFListMdTypeToRetrieve` (or `require('sf').list_md_type_to_retrieve()`) to show the
   list in a pop-up (requires the fzf-lua plugin) and select one to
   download all metadata of this type to local.

<br>

## ⚡Apex Test

There are two categories of test actions.

✨ Use-case 1: without code coverage info

You can,

- Run all tests in the current file by `<leader>ta`
- Run the test under the cursor by `<leader>tt`
- Select tests from the current file by `<leader>to`

These commands quickly run and verify the pass/fail result.

🌩️ Use-case 2: with code coverage info

Use the same hotkeys but capitalize the last letter:

- `<leader>tA`
- `<leader>tT`
- `<leader>tO`

These test results contains code coverage information.

After running these commands successfully, the test result is saved locally, and the
covered/uncovered lines are illustrated as sign-icons next to the line number (screenshot below).

🧩 Screenshot

Test finishes in `CrudTest.cls` with `UNCOVERED LINES: 9,10,11,13,14` and the line coverage in `Crud.cls` is indicated with green/red icon
signs.

<br>

![Image 012](https://github.com/user-attachments/assets/c9539cec-7dcc-48fc-b8e8-929cc1514b07)

<br>

📏 Note.

- The line coverage icon shows automatically if the `auto_display_code_sign` setting is set to `true` (default).
- Toggle sign icon on/off with the `\s` hotkey (or `require'sf'.toggle_sign()`).

🏗️ Jump to next uncovered hunk

- Use `]v` and `[v` to jump to the next/previous uncovered hunk.

📊 Apex file code coverage info

- `require('sf').covered_percent()` has the current Apex file code coverage information. You can
  display it as you want. For example, I use it in my status line next to target_org, configred in lualine.nvim [here](https://github.com/xixiaofinland/dotfiles-nix/blob/644b5d0791d40afa1bd37b5c97e269629a2ca817/dotfiles/nvim/lua/plugins/lualine.lua#L21)

<br>

## 🖥️ Integrated terminal

The integrated terminal is designed to

- accept input from hotkeys and user commands, such as "retrieve current metadata"
  `<leader>sr`
- be a read-only buffer. It's, by design, not allowed to manually type commands
- be disposable. The output text of the previous command is removed when a new command is invoked
- be auto-prompt, in case the terminal is hidden at the moment the command execution completes. This is handy when you have a long-running command.

You can pass any shell command into `run()` method to execute it in the integrated
terminal. For instance, `require('sf').run('ls -la')`.

<br>

## 🏃 Enhanced jump-to-definition (Apex)

Salesforce's Apex LSP (apex-jorje-lsp.jar) offers a jump-to-definition feature, but it's not
perfect. You may encounter cases where it doesn't function correctly in certain codebases. To
address this, the LSP jump-to-definition is enhanced by ctags.

If you don't yet know what ctags is, it's wise to google "ctags in vim" to prepare a bit more.

Ctags is ideal in this scenario because:
- It is natively supported by Nvim/Vim, although you need to install `ctags` yourself
- The default `<C-]>` key in Nvim will first attempt to jump with LSP and fall back to ctags if LSP fails

There are several versions of ctags, this repo uses [universal
ctags](https://github.com/universal-ctags/ctags). So you need to install it to use this feature.

### How to use it?

`require('sf').create_ctags()` generates the ctags file in the project root.
Using the `<C-]>` key for jump-to-definition will automatically use both LSP and ctags in order.
`require('sf').create_and_list_ctags()` will update ctags and list the tags symbols in  `fzf-lua`
plugin.

<br>

## 🏆 Contributions

Please create an issue to discuss your PR before submitting it. This ensures
that the PR will be merged.

The PR is highly recommended to be submitted against the `dev` branch.

The `help.txt` file is auto-generated from the comments with the `---` suffix
before each function in [init.lua](https://github.com/xixiaofinland/sf.nvim/blob/dev/lua/sf/init.lua). The plugin
uses `mini.doc` to automatically generate `help.txt` from these `---` suffixed comments. Therefore,
add your doc content in `init.lua` without touching `help.txt` is sufficient.

<br>

### 🤝 Contributors

Thanks to the following people for contributing to this project:

- [@ognjen-vuceljic](https://github.com/ognjen-vuceljic)
- ![GitHub Profile Image](https://github.com/waltonzt.png?size=50) [@waltonzt](https://github.com/waltonzt)
- ![GitHub Profile Image](https://github.com/FedeAbella.png?size=50) [@FedeAbella](https://github.com/FedeAbella)

<br>

## 📜 License
MIT.
