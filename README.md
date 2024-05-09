![Image](https://github.com/xixiaofinland/sf.nvim/assets/13655323/454d4a3d-d455-43f6-b44b-506862106b66)
<p align="center">

<img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=fff&style=for-the-badge" alt="Neovim" />

<img src="https://img.shields.io/badge/Made%20With%20Lua-2C2D72?logo=lua&logoColor=fff&style=for-the-badge" alt="made with lua" >

</p>

<h1 align="center">Sf.nvim</h1>
<p align="center">📸 Offer common functionalities for Salesforce development</p>

## ✨ Features
- 🔥 Push, retrieve, and create metadata files
- 💻 Integrated scratch terminal for on-the-fly commands
- 😎 Diff files between local and org environments
- 🤩 Display target org in the status line
- 👏 Access to a pre-downloaded list of metadata files
- 🤖 Facilitate quick Apex test runs

## 🎦 Video Intro (6 mins)

[![Feature Intro (6 min)](https://img.youtube.com/vi/MdqPgHIb1pw/0.jpg)](https://www.youtube.com/watch?v=MdqPgHIb1pw)

## Installation
Install using Lazy.nvim by adding the following configuration to your setup:

```lua
return {
  'xixiaofinland/sf.nvim',
  branch = 'dev',

  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'ibhagwan/fzf-lua',
  },

  config = function()
    require('sf').setup()  -- Call setup() to initialize the plugin!
  end
}
```

Additional configuration can be passed into setup(). Below are the default settings

```lua
require('sf').setup({
      -- No need to add these lines if you are content with the default settings.

      -- Enables hotkeys and user commands for these filetypes
      hotkeys_in_filetypes = ["apex", "sosl", "soql", "javascript", "html"],

      -- When `false` (default), hotkeys are enabled for filetypes defined above.
      -- When `true`, hotkeys are only enabled in a Salesforce project folder.
      enable_hotkeys_only_in_sf_project_folder = false,

      -- Defines metadata file types to be retrieved by Ex command `SFPullMd`
      types_to_retrieve = ["ApexClass", "ApexTrigger", "StaticResource", "LightningComponentBundle"],
})
```

## Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli)
- Nvim-treesitter with the Apex parser installed (ensure_installed = { "apex", "soql", "sosl" }), e.g., [in my settings](https://github.com/xixiaofinland/dotfiles/blob/main/.config/nvim/lua/plugins/nvim-tree-sitter.lua)
- fzf-lua plugin for executing Ex commands like `SFListMdToRetrieve` and `SFListMdTypeToRetrieve`

## Usage

Checking all public-facing features through `:h sf.nvim` or by consulting the [help.txt file](https://github.com/xixiaofinland/sf.nvim/blob/dev/doc/sf.txt).

### Display target_org

Upon starting Nvim, Sf.nvim executes SfFetchOrgList to fetch and save authenticated org names. Display the target_org in your status line to facilitate command execution against the target org.

Example configuration using lualine.nvim with target_org(`xixiao100`):

```lua
    sections = {
      lualine_c = { 'filename', {
        "require'sf'.get_target_org()",
      } },
```
![Image 012](https://github.com/xixiaofinland/sf.nvim/assets/13655323/645a6625-aec6-4593-931e-84534ad3ac4c)

### Commands

For a full list of commands and hotkeys, see the middle section of this file [here](https://github.com/xixiaofinland/sf.nvim/blob/main/lua/sf/config.lua).

Example:

- Press `<leader>s` to activate hotkeys as shown in the screenshot below.
![Image 007](https://github.com/xixiaofinland/sf.nvim/assets/13655323/c0bc474c-3d2f-4fad-9bc0-5076cf4dd108)

Type `:Sf` in Ex mode will list all user commands:
![Image 005](https://github.com/xixiaofinland/sf.nvim/assets/13655323/d5e9b626-e75f-4ecb-befc-c8535da8f2d9)

### Shell Commands

you can pass any shell command into `run()` method to execute it in the integrate
terminal. For instance, `require('sf').run('sf org list')`.

## License
MIT.
