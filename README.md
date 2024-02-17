# Sf.nvim

Offer common functionalities for Salesforce development

## Modules

- `SFOrg`  The module to interact with Salesforce org.
- `SFTerm` The module to run commands in an integrated floating terminal.
- `SFTest` The module to facilitate test running.

Tip: use `:h SFOrg`, `:h SFTerm`, `:h SFTest` to see more details.

## Usage

### Hotkeys

Default hotkeys are defined as part of the package [here](https://github.com/xixiaofinland/sf.nvim/blob/dev/plugin/sf.lua).

These hotkeys are enabled ONLY when the file in the current buffer meets both conditions:
- with filetype `apex`, `javascript`, or `html` and
- in a salesforce project folder (i.e. has `.forceignore` or `sfdx-project.json`)

### Display target_org

When Nvim starts, sf.nvim runs `SfFetchOrgList` to automatically fetch the authenticated org names and save the target_org in `require'sf'.target_org`.
As majority of commands in sf.nvim executes against a target_org, it's wise to display target_org name in your statusline.

For example, I use lualine.nvim, and configure/show it as below.

```
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.target_org",
      } },
```

### Often used commands

Often used commands are also saved as user commands: Ex `:Sf` then hit tab to list all defined user commands.

For example:

- `SfSetTargetOrg` choose target_org
- `SfDiff` diff the file content between local and org version in side-by-side windows
- `SfToggle` toggle the integrated floating terminal window
- `SfSaveAndPush` save the current file and push to target_org
- `SfRetrieve` retrieve the current file from target_org
- `SfCancelCommand` Terminate the running command in the integrated terminal
- `SfRunAllTestsInThisFile` run all Apex tests in the current file
- `SfRunCurrentTest` run the Apex test under the cursor
- `SfRepeatTest` repeat the previous test command

## Install

Lazy.nvim

```
return {
  'xixiaofinland/sf.nvim',
  branch = 'main', -- use dev branch for cutting-edge features

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
  },
}

```

