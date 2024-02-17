# Sf.nvim

Offer common functionalities for Salesforce development

## Modules

- `SFOrg`  The module to interact with Salesforce org. `:h SFOrg` to see its method description.
- `SFTerm` The module to run commands in an integrated floating terminal. `:h SFTerm` to see its method description.
- `SFTest` The module to facilitate test running. `:h SFTest` to see its method description.


## Usage

Often used commands are saved as user commands: Ex `:Sf` then hit tab to list all defined user commands.

Take a peek at all user commands and default hotkeys [here](https://github.com/xixiaofinland/sf.nvim/blob/dev/plugin/sf.lua).


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

