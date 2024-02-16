# Sf.nvim

Offer common functionalities for Salesforce development

## Usage

Often used commands are saved as user commands: Ex `:Sf` then hit tab to list all defined user commands.

Take a peek at all user commands and default hotkeys [here](https://github.com/xixiaofinland/sf.nvim/blob/dev/plugin/sf.lua).

## Modules

- `SFOrg`  The module to interact with Salesforce org
- `SFTerm` The module to run commands in an integrated floating terminal
- `SFTest` The module to facilitate test running

Note. use `:h` (e.g. `:h SFOrg`) to read more information.

## Install

Lazy.nvim

```
return {
  'xixiaofinland/sf.nvim',
  branch = 'dev', -- use dev branch for nightly features

  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-telescope/telescope.nvim",
  },
}

```

