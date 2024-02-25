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
- 🤖 predefined hotkeys and user commands
  

## Prerequirements
- [Salesforce `sf` CLI](https://developer.salesforce.com/tools/salesforcecli)

## Install
Lazy.nvim

```lua
return {
  'xixiaofinland/sf.nvim',
  branch = 'main', -- use dev branch for cutting-edge features

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
  },
}

```

## Usage

All public facing functions can be checked by `:h sf.nvim` or in [help.txt](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt)

### Display target_org

When Nvim starts, sf.nvim auto-runs `SfFetchOrgList` to fetch the authenticated org names and save the target_org in `require'sf'.target_org`.
As a majority of commands execute against a target_org, it's wise to display target_org in your statusline.

For example, I use lualine.nvim, and configure/show target_org(`sandbox1`) as below.

```lua
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.get_target_org()",
      } },
```
![Image 006](https://github.com/xixiaofinland/sf.nvim/assets/13655323/75670011-68da-48d6-896e-de7ce637ee17)


### Commands
Hotkeys and user commands are defined [here](https://github.com/xixiaofinland/sf.nvim/blob/365ae4cedd5ea6cd78f4206153d8cc4f148cfb77/plugin/sf.lua#L53).

They are enabled ONLY when the current buffer is:
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
