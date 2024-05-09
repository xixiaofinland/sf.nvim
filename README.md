![Image](https://github.com/xixiaofinland/sf.nvim/assets/13655323/454d4a3d-d455-43f6-b44b-506862106b66)
<p align="center">

<img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=fff&style=for-the-badge" alt="Neovim" />

<img src="https://img.shields.io/badge/Made%20With%20Lua-2C2D72?logo=lua&logoColor=fff&style=for-the-badge" alt="made with lua" >

</p>

<h1 align="center">Sf.nvim</h1>
<p align="center">📸 Offer common functionalities for Salesforce development</p>

## ✨Features
- 🔥 Push/retrieve/create metadata files
- 💻 Integrated scratch terminal
- 😎 Diff file between local and org
- 🤩 Target org shows in status line
- 👏 pre-downloaded metadata file list
- 🤖 Quick Apex test runs

## 🎦Video intro (6mins)

[![Feature intro (6min)](https://img.youtube.com/vi/MdqPgHIb1pw/0.jpg)](https://www.youtube.com/watch?v=MdqPgHIb1pw)

## Install
Lazy.nvim

```lua
return {
  'xixiaofinland/sf.nvim',
  branch = 'dev',
  dir = '~/projects/sf.nvim',

  dependencies = {
    "ibhagwan/fzf-lua",
    'nvim-treesitter/nvim-treesitter',
  },

  config = function()
    require('sf').setup() -- important to call setup() to init the plugin!
  end
}

```

You can also pass a config table into `setup()`. It can be defined as:

```lua
-- These are the default settings, no need to set them if you are happy already.

require('sf').setup({

      -- Hotkeys and user commands are enabled for these filetypes
      hotkeys_in_filetypes = {
        "apex", "sosl", "soql", "javascript", "html"
      },

      -- When set to `false`(default), filetypes defined in `hotkeys_in_filetypes` have
      -- hotkeys and user commands enabled.
      -- When set to `true`, hotkeys and user commands are only enabled when the file also
      -- resides in a sf project folder (i.e. has `.forceignore` or `sfdx-project.json` in the root path)
      enable_hotkeys_only_in_sf_project_folder = false,

      -- Define what metadata file names to be listed in `list_md_to_retrieve()` (<leader>ml)
      types_to_retrieve = {
        "ApexClass",
        "ApexTrigger",
        "StaticResource",
        "LightningComponentBundle"
      },
    })
```

## Prerequisites
- [sf cli](https://developer.salesforce.com/tools/salesforcecli)
- Make sure apex parser is installed in nvim-treesitter plugin: `ensure_installed = { "apex", "soql", "sosl"}`, e.g.: in [my setting](https://github.com/xixiaofinland/dotfiles/blob/main/.config/nvim/lua/plugins/nvim-tree-sitter.lua)


## Usage

All public facing functions can be checked by `:h sf.nvim` or in [help.txt](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt)

### Display target_org

When Nvim starts, Sf.nvim runs `SfFetchOrgList` to fetch the authenticated org names and save the target_org name in the plugin if it exists.
As a majority of commands execute against a target_org, it's recommended to display target_org in your statusline.

For example, I use lualine.nvim, and configure/show target_org(`xixiao100`) as below.

```lua
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.get_target_org()",
      } },
```
![Image 012](https://github.com/xixiaofinland/sf.nvim/assets/13655323/645a6625-aec6-4593-931e-84534ad3ac4c)

### Commands
Hotkeys and user commands are defined in the middle of this file [here](https://github.com/xixiaofinland/sf.nvim/blob/main/lua/sf/config.lua).

When they are enabled:

type `<leader>s` should see hotkeys as in the screenshot.
![Image 007](https://github.com/xixiaofinland/sf.nvim/assets/13655323/c0bc474c-3d2f-4fad-9bc0-5076cf4dd108)

Type `:Sf` in Ex will list all user commands:
![Image 005](https://github.com/xixiaofinland/sf.nvim/assets/13655323/d5e9b626-e75f-4ecb-befc-c8535da8f2d9)

### Self defined commands
Chances are you have more than the predefined command to run, such as `sf org
list`.

you can pass the command into `run()` method to execute it in the integrate
terminal. For instance, `require('sf').run('sf org list')`.

## License
MIT.
