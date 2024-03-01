![Image](https://github.com/xixiaofinland/sf.nvim/assets/13655323/454d4a3d-d455-43f6-b44b-506862106b66)
<p align="center">

<img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=fff&style=for-the-badge" alt="Neovim" />

<img src="https://img.shields.io/badge/Made%20With%20Lua-2C2D72?logo=lua&logoColor=fff&style=for-the-badge" alt="made with lua" >

</p>

<h1 align="center">Sf.nvim</h1>
<p align="center">📸 Offer common functionalities for Salesforce development</p>

## ✨Features
- 🔥 Push/retrieve metadata files
- 💻 Integrated scratch terminal
- 😎 Diff file between local and org
- 🤩 Target org shows in status line
- 👏 pre-downloaded metadata file list
- 🤖 Quick Apex test runs

## 🎦Video intro (6mins)

[![Feature intro (6min)](https://img.youtube.com/vi/MdqPgHIb1pw/0.jpg)](https://www.youtube.com/watch?v=MdqPgHIb1pw)

## Prerequirements
- [Salesforce sf CLI](https://developer.salesforce.com/tools/salesforcecli)

## Install
Lazy.nvim

```lua
return {
  'xixiaofinland/sf.nvim',
  branch = 'main',

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
  },
}

```

## Usage

All public facing functions can be checked by `:h sf.nvim` or in [help.txt](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt)

### Display target_org

When Nvim starts, Sf.nvim runs `SfFetchOrgList`(i.e. `sf org list`) to fetch the authenticated org names and save the target_org name in the plugin if it exists.
As a majority of commands execute against a target_org, it's recommended to set (use `SfSetTargetOrg`) and display target_org in your statusline.

For example, I use lualine.nvim, and configure/show target_org(`xixiao100`) as below.

```lua
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.get_target_org()",
      } },
```
![Image 012](https://github.com/xixiaofinland/sf.nvim/assets/13655323/645a6625-aec6-4593-931e-84534ad3ac4c)

### Commands
Hotkeys and user commands are defined in the middle of this file [here](https://github.com/xixiaofinland/sf.nvim/blob/dev/plugin/sf.lua).

They are enabled ONLY when the current buffer is both:
- `apex`, `javascript`, or `html` filetype
- and in a sf project folder (i.e. has `.forceignore` or `sfdx-project.json` in the root path)

When both conditions are met, type `<leader>s` should see hotkeys as in the screenshot.
![Image 007](https://github.com/xixiaofinland/sf.nvim/assets/13655323/c0bc474c-3d2f-4fad-9bc0-5076cf4dd108)

Type `:Sf` in Ex will list all user commands:
![Image 005](https://github.com/xixiaofinland/sf.nvim/assets/13655323/d5e9b626-e75f-4ecb-befc-c8535da8f2d9)

### Some often used commands

- `SfSetTargetOrg` set a target_org by choosing from authenticated org names
- `SfDiff` diff the file content between local and target_org version in side-by-side windows
---------------
- `SfToggle` toggle the integrated floating terminal window
- `SfSaveAndPush` save the current file and push to target_org
- `SfRetrieve` retrieve the current file from target_org
- `SfCancelCommand` Terminate the running command in the integrated terminal
---------------
- `SfRunAllTestsInThisFile` run all Apex tests in the current file
- `SfRunCurrentTest` run the Apex test under the cursor
- `SfRepeatTest` repeat the previous test command
- `SfOpenTestSelect` open a top-window with Apex test list of the current file

## License
MIT.
