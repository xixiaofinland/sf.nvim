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
- `SFTest` The module to facilitate test running.

Tip: use `:h SFOrg`, `:h SFTerm`, `:h SFTest` to see more details.

# Usage

## Hotkeys

Default hotkeys are defined as part of the package [here](https://github.com/xixiaofinland/sf.nvim/blob/556f0f5b671098c12916730fe68d4a7f5de3ffd2/plugin/sf.lua#L119).

These hotkeys are enabled ONLY when the current file is:
- `apex`, `javascript`, or `html` filetype and
- in a sf project folder (i.e. has `.forceignore` or `sfdx-project.json` in the root path)

When both conditions are met, type `<leader>s` should see hotkeys as in the screenshot.
![Image 007](https://github.com/xixiaofinland/sf.nvim/assets/13655323/c0bc474c-3d2f-4fad-9bc0-5076cf4dd108)

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

## Often used commands

Often used commands are also saved as user commands: Ex `:Sf` then hit the tab to list all defined user commands.
![Image 005](https://github.com/xixiaofinland/sf.nvim/assets/13655323/d5e9b626-e75f-4ecb-befc-c8535da8f2d9)

From SfOrg module:

- `SfSetTargetOrg` set a target_org by chooswng from authenticated org names
- `SfDiff` diff the file content between local and target_org version in side-by-side windows
- `SfDiffInOrg` diff the file content between local and chosen org version in side-by-side windows
- `SfPullMetadataTypeList` pull names of MetadataType into a json file and save in sf project "md" folder
- `SfRetrieveMetadataType` use names pulled from `SfPullMetadataTypeList` to fuzzy search and retrieve all content
- `SfPullMetadataList` pull names of all metadata into corresponding json files and save in sf project "md" folder
- `SfRetrieveMetadata` use names pulled from `SfPullMetadataList` to fuzzy search and retrieve a metadata content

From SfTerm module:

- `SfToggle` toggle the integrated floating terminal window
- `SfSaveAndPush` save the current file and push to target_org
- `SfRetrieve` retrieve the current file from target_org
- `SfCancelCommand` Terminate the running command in the integrated terminal

From SfTest module:

- `SfRunAllTestsInThisFile` run all Apex tests in the current file
- `SfRunCurrentTest` run the Apex test under the cursor
- `SfRepeatTest` repeat the previous test command
- `SfOpenTestSelect` open a top-window with Apex test list of the current file
