# Sf.nvim

Offer common functionalities for Salesforce development

# Install

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

About the dependencies:
 - `nvim-treesitter` includes Apex parser and syntax highlight. There is no reason you don't install it at the first place. It's also used in sf.nvim to identify Apex test class/menthod.
 - `telescope.nvim` is only used in `SfRetrieveMetadata` and `SfRetrieveMetadataType` to fuzzy search metadata. You can leave it out if these two functions are not in use.

# Modules

- `SFOrg`  The module to interact with Salesforce org.
- `SFTerm` The module to run commands in an integrated floating terminal.
- `SFMd`   The module to deal with metadata and metadata-type.
- `SFTest` The module to facilitate test running.

Tip: You can read help.txt [here](https://github.com/xixiaofinland/sf.nvim/blob/main/doc/sf.txt), or use `:h SFOrg`, `:h SFTerm`, `:h SFMd`, and `:h SFTest` in Nvim to see more details.

# Usage

## Hotkeys and User commands

Hotkeys and user commands are defined [here](https://github.com/xixiaofinland/sf.nvim/blob/365ae4cedd5ea6cd78f4206153d8cc4f148cfb77/plugin/sf.lua#L53).

They are enabled ONLY when the file in the current buffer is:
- `apex`, `javascript`, or `html` filetype
- and in a sf project folder (i.e. has `.forceignore` or `sfdx-project.json` in the root path)

When both conditions are met, type `<leader>s` should see hotkeys as in the screenshot.
![Image 007](https://github.com/xixiaofinland/sf.nvim/assets/13655323/c0bc474c-3d2f-4fad-9bc0-5076cf4dd108)

Type `:Sf` in Ex will list all user commands:
![Image 005](https://github.com/xixiaofinland/sf.nvim/assets/13655323/d5e9b626-e75f-4ecb-befc-c8535da8f2d9)

## Display target_org

When Nvim starts, sf.nvim auto-runs `SfFetchOrgList` to fetch the authenticated org names and save the target_org in `require'sf'.target_org`.
As a majority of commands execute against a target_org, it's wise to display target_org in your statusline.

For example, I use lualine.nvim, and configure/show target_org(`sandbox1`) as below.

```lua
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.target_org",
      } },
```
![Image 006](https://github.com/xixiaofinland/sf.nvim/assets/13655323/75670011-68da-48d6-896e-de7ce637ee17)

## Some often used commands

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
