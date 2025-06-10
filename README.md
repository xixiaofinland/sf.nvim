![Image](https://github.com/xixiaofinland/sf.nvim/assets/13655323/454d4a3d-d455-43f6-b44b-506862106b66)
<p align="center">
<img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=fff&style=for-the-badge" alt="Neovim" />
<img src="https://img.shields.io/badge/Made%20With%20Lua-2C2D72?logo=lua&logoColor=fff&style=for-the-badge" alt="made with lua" >
</p>
<h1 align="center">Sf.nvim</h1>
<p align="center">📸 A Neovim plugin for Salesforce development</p>

# 📖 Table of Contents

- [Features](#-features)
- [Intro video](#-intro-video-6min)
- [Prerequisites](#-prerequisites)
- [Installation](#%EF%B8%8F--installation)
- [Configuration](#%EF%B8%8F-configuration)
- [Keys](#-keys)
- [List/retrieve metadata](#-feature-listretrieve-metadata-and-metadata-types)
- [Apex test](#apex-test)
- [Display target org and code coverage](#-display-target_org-and-code-coverage)
- [Terminal](#%EF%B8%8F-terminal)
- [Apex jump](#-enhanced-jump-to-definition-apex)
- [Read More](#-read-more)
- [Contributions](#-contributions)

## ✨ Features

In a nutshell, All features are supplied via the list of `Sf.*` functionalities in
[init.lua](./lua/sf/init.lua). You can surf the code comments as the manual or `:h
sf.nvim`, which is auto-generated from those comments.

All the features are categorized as:

- 🔥 Apex/Lwc/Aura: push, retrieve, create
- 💻 Integrated term or overseer.nvim
- 😎 File diff: local v.s. org
- 🤩 Target-org icon
- 👏 Org Metadata browsing
- 🤖 Quick apex test run
- ✨ Test report and code coverage info
- 🦘 Enhanced jump-to-definition (Apex)

In addition to the features, user commands and default hotkeys are also supplied, see
[Keys](#-keys).

<br>


## 🎦 Intro video (6min)

[![Feature Intro (6 min)](https://img.youtube.com/vi/MdqPgHIb1pw/0.jpg)](https://www.youtube.com/watch?v=MdqPgHIb1pw)

<br>

## 📝 Prerequisites

💡 Plugin comes with a health check feature. Run `:check sf` to auto-check prerequiste statistics.

- 🌐 [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- 🐢 Nvim v0.10 or newer ([why must > 0.10?](https://github.com/xixiaofinland/sf.nvim/issues/73))
- 📦 Salesforce relevant parsers (i.e. "apex", "soql", "sosl", and "sflog") in Nvim-treesitter. Install them like [in my settings](https://github.com/xixiaofinland/dotfiles-nix/blob/55081dd2394030cc418778b311ba3fd7fb3ff6c8/dotfiles/nvim_config/lua/plugins/nvim-tree-sitter.lua#L28)
- 🔍 (Optional) fzf-lua plugin for executing `:SF md list` and `SFListMdTypeToRetrieve` (Why not
  telescope.nvim? Because its UI is slow)
- 🔍 (Optional) [universal ctags](https://github.com/universal-ctags/ctags) is used to enhance [Apex jump](#-enhanced-jump-to-definition-apex)
- 🔍 (Optional) [overseer.nvim](https://github.com/stevearc/overseer.nvim) if you'd like to use the overseer integration


![Image 019](https://github.com/user-attachments/assets/aad0ac11-f980-423b-8332-a2b4359fb4ae)

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

The hotkeys are disabled by default!
The user commands are **ONLY** enabled when your current path (`:h cwd`) or the current opened file
is inside a sf project folder (i.e. has `.forceignore` or `sfdx-project.json` in the root path).

Run `:lua require'sf.util'.get_sf_root()` to verify if the current opened file
resides in sf project folder. When no error is printed it means the file is in a sf project folder.

<br>

## 🛠️ Configuration

Custom configuration can be passed into `setup()` Below are the default
settings:

```lua
require('sf').setup({
  -- Unless you want to customize, no need to copy-paste any of these
  -- They are applied automatically

  -- This plugin has many default hotkey mappings supplied
  -- This flag enable/disable these hotkeys defined
  -- It's highly recommended to set this to `false` and define your own key mappings
  -- Set to `true` if you don't mind any potential key mapping conflicts with your own
  enable_hotkeys = false,

  -- this setting takes effect only when You have "enable_hotkeys = true"(i.e. use default supplied hotkeys).
  -- In the default hotkeys, some hotkeys are on "project level" thus always enabled. Examples: "set default org", "fetch org info".
  -- Other hotkeys are enabled when only metadata filetypes are loaded in the current buffer. Example: "push/retrieve current metadata file"
  -- This list defines what metadata filetypes have the "other hotkeys" enabled.
  -- For example, if you want to push/retrieve css files, it needs to be added into this list.
  hotkeys_in_filetypes = {
    "apex", "sosl", "soql", "javascript", "html"
  },

  -- When Nvim is initiated, the sf org list is automatically fetched and target_org is set (if available) by `:SF org fetchList`
  -- You can set it to `false` and have a manual control
  fetch_org_list_at_nvim_start = true,

  -- Define what metadata to be listed in `list_md_to_retrieve()` (<leader>ml)
  -- Salesforce has numerous metadata types. We narrow down the scope of `list_md_to_retrieve()`.
  types_to_retrieve = {
    "ApexClass",
    "ApexTrigger",
    "StaticResource",
    "LightningComponentBundle"
  },

  -- The terminal strategy to use for running tasks.
  -- "integrated" - use the integrated terminal.
  -- "overseer" - use overseer.nvim to run terminal tasks. (requires overseer.nvim as a dependency).
  terminal = "integrated",

  -- Configuration for the integrated terminal
  term_config = {
    blend = 10,     -- background transparency: 0 is fully opaque; 100 is fully transparent
    dimensions = {
      height = 0.4, -- proportional of the editor height. 0.4 means 40%.
      width = 0.8,  -- proportional of the editor width. 0.8 means 80%.
      x = 0.5,      -- starting position of width. Details in `get_dimension()` in raw_term.lua source code.
      y = 0.9,      -- starting position of height. Details in `get_dimension()` in raw_term.lua source code.
    },
  },

  -- By default, the plugin uses the default package from sfdx-project.json.
  -- If no packages are found, falls back to the value specified in 'default_dir'. If multiple packages are available,
  -- you can override the current working package using |Sf.set_current_package|
  default_dir = '/force-app/main/default/',

  -- the folder this plugin uses to store intermediate data. It's under the sf project root directory.
  plugin_folder_name = '/sf_cache/',

  -- after the test running with code coverage completes, display uncovered line sign automatically.
  -- you can set it to `false`, then manually run toggle_sign command.
  auto_display_code_sign = true,

  -- code coverage sign icon colors
  code_sign_highlight = {
    covered = { fg = "#b7f071" }, -- set `fg = ""` to disable this sign icon
    uncovered = { fg = "#f07178" }, -- set `fg = ""` to disable this sign icon
  },
})
```

<br>

## 🔑 Keys

This plugin supplies both user commands (`:h user-commands`) and default hotkeys(`:h mapping`).

Note! Default hotkeys are **disabled** by default in the config setting.

### 🖥️ User commands

User commands are categories into two level subcommands (`:SF sub_cmd1 sub_cmd2`) to leverage the `tab`
suggestion.

For example,

1. type `:SF<space>` and hit `tab` to list available categories(i.e. `sub_cmd1`) as screenshot 1.
2. Then select `test<space>` and hit `tab` again to list the available `sub_cmd2` options in `test`
category as screenshot 2
3. Finally choose `:SF test allTestsInThisFile` and hit `<enter>` to run all Apex tests in the current file.

![Image 020](https://github.com/user-attachments/assets/725e5d6a-843e-4434-a0c9-a9e72dcb1528)

![Image 021](https://github.com/user-attachments/assets/ab78ef40-6606-4575-b664-a1f905092dc4)



### ⌨️ Default hotkeys

This plugin comes with many default hotkeys (all defined in [this file](./lua/sf/sub/config_user_key.lua)), which may conflict and overwrite your existing hotkeys.
Thus these hotkeys are **disabled** by default in the config setting.

It is also recommended to disable them and define the ones as you wish.
The toggling is in the configuration by setting the `enable_hotkeys` option.

For example,
```
return {
    'xixiaofinland/sf.nvim',
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        "ibhagwan/fzf-lua",
    },
    config = function()
        require('sf').setup()

        -- all your key definitions put below
        local Sf = require('sf')
        vim.keymap.set('n', '<leader>ss', Sf.set_target_org, { desc = "set local" })
        vim.keymap.set('n', '<leader>sS', Sf.set_global_target_org, { desc = "set global" })
    end
}
```

### Often used default keys

In case you decide to go with the default hotkeys:

| Default key       | function name           | Explain           |
| ----------| ------------------| ------------------|
| `<leader>ss`     | set_target_org           | set target_org |
| `<leader>sf`     | fetch_org_list              |fetch/refresh orgs info|
| `<leader><leader>`     |toggle_term|terminal toggle|
| `<leader>sp`     |save_and_push|push current file|
| `<leader>sr`     |retrieve|retrieve current file|
| `<leader>ta`     |run_all_tests_in_this_file|run all Apex tests in current file|
| `<leader>tt`     |run_current_test|test this under cursor|
| `<leader>tr`     |repeat_last_tests|repeat the last test|
| `<leader>to`     |open_test_select|open a buffer to select tests|
| `<leader>ct`     |create_ctags |create ctags file|
| `<leader>sq`     | run_highlighted_soql |Deault key is only enabled in visual model. Highlight selected text will be run as SOQL in the term|
|`\s`|toggle_sign |Show/hide line coverage sign icon|
|`]v`|uncovered_jump_forward |jump to next test uncovered hunk|
|`[v`|uncovered_jump_backward |jump to last test uncovered hunk|

All keys are listed in `:h sf.nvim` or [help.txt file](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt).

Example:

- If you have [which-key](https://github.com/folke/which-key.nvim) or a similar plugin installed, pressing `<leader>s` will hint to you what keys are enabled as
  shown in the screenshot below. Remember that default hotkeys are **disabled by default.
![Image 003](https://github.com/xixiaofinland/sf.nvim/assets/13655323/85faa8cb-b1df-40dd-a1bf-323f94bbf13c)

<br>

### 💡 Run any command in the term

The integrated term (i.e. SFTerm) is a general purpose one, you can pass any shell command into
`run()` method to execute it terminal. For instance, `require('sf').run('ls -la')`, then define it
as your key:

```lua
vim.keymap.set('n', '<leader>sk', require('sf').run('ls -la'), { noremap = true, silent = true, desc = 'run ls -la in the terminal' })
```
<br>

## 🚀 Feature: List/retrieve metadata and metadata types

Sometimes you don't know what metadata the target org contains, and you want to
list them and fetch specific ones. Steps:

1. Retrieve the metadata data by running the user command `:SF md pull`.
2. Run `:SF md list` (or `require('sf').list_md_to_retrieve()`) to show
   the list in a pop-up (requires the fzf-lua plugin) and select one to
   download to local.

Sometimes you want to fetch all files of a certain metadata type (Apex class,
LWC, Aura, etc.). You can list them and fetch all of a specific type. Steps:

1. Retrieve the metadata types by running the user command `:SF mdtype pull`.
2. Run `:SF mdtype list` (or `require('sf').list_md_type_to_retrieve()`) to show the
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

<br>

## 🎯 Display target_org and code coverage

### target_org

Upon starting Nvim, Sf.nvim executes `:SF org fetchList` to fetch and save
authenticated org names. Display the target_org in your status line to
facilitate command execution against the target org.

If you don't have a default target_org, then this value is empty. You can use `<leader>ss` to set it.

Example configuration using lualine.nvim with target_org(`xixiao100`):

```lua
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.get_target_org()",
      } },
```

![Image 012](https://github.com/xixiaofinland/sf.nvim/assets/13655323/645a6625-aec6-4593-931e-84534ad3ac4c)

### code coverage

`require('sf').covered_percent()` has the current Apex file code coverage information.
You can
  display it as you want. For example, I display it (`92`) in my status line next to target_org (`devhub`), configured in lualine.nvim [here](https://github.com/xixiaofinland/dotfiles-nix/blob/644b5d0791d40afa1bd37b5c97e269629a2ca817/dotfiles/nvim/lua/plugins/lualine.lua#L21)

![Image 015](https://github.com/user-attachments/assets/3b1ba158-dbcb-4516-a53c-61a824772933)

<br>

## 🖥️ Terminal

### Integrated terminal

![Image 022](https://github.com/user-attachments/assets/bd61e9fc-fa0d-4782-8f2d-68e90dcb0d10)

The integrated terminal is designed to

- accept input from hotkeys and user commands, such as "retrieve current metadata file"
  `<leader>sr`
- be a read-only buffer. It's, by design, not allowed to manually type commands
- be disposable. The output text of the previous command is removed when a new command is invoked
- be auto-prompt, in case the terminal is hidden at the moment the command execution completes. This is handy when you have a long-running command.

You can pass any shell command into `run()` method to execute it in the integrated
terminal. For instance, `require('sf').run('ls -la')`.

### Overseer.nvim

As an alternative to the integrated terminal, [overseer.nvim](https://github.com/stevearc/overseer.nvim) can be used to execute terminal commands.

Once enabled

- commands executed by Sf.nvim will be created in overseer as tasks
- the overseer task list can be show or hidden via `:OverseerToggle`

To enable, ensure overseer.nvim is a dependency and set the appropriate flag in your configuration:

```
return {
    'xixiaofinland/sf.nvim',
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
        'stevearc/overseer.nvim',
        "ibhagwan/fzf-lua",
    },
    config = function()
        require('sf').setup({ terminal = 'overseer' })
    end
}
```

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

`:SF create ctags` or `require('sf').create_ctags()` generates the ctags file in the project root.
Using the `<C-]>` key for jump-to-definition will automatically use both LSP and ctags in order.
`:SF create ctagsAndList` or `require('sf').create_and_list_ctags()` will update ctags and list the tags symbols in  `fzf-lua`
plugin.

<br>

## 📚 Read More

Full documentation can be accessed via `:h sf.nvim` or [help.txt file](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt).

<br>

## 🏆 Contributions

Please create an issue to discuss your PR before submitting it. This ensures
that the PR will be merged.

The PR should be done against `main` branch.
Commit messages should follow [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/), or the
PR would fail in the status check.

For example,

- If it's a new feature, the commit message could be "feat: add a new user command".
- If it's a bug fix, the commit message could be "fix: eliminate the error".

The `help.txt` file is auto-generated from the comments with the `---` suffix
before each function in [init.lua](https://github.com/xixiaofinland/sf.nvim/blob/dev/lua/sf/init.lua). The plugin
uses `mini.doc` to automatically generate `help.txt` from these `---` suffixed comments. Therefore,
add your doc content in `init.lua` without touching `help.txt` is sufficient.

<br>

## 📜 License
MIT.
