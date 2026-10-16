![Image](https://github.com/xixiaofinland/sf.nvim/assets/13655323/454d4a3d-d455-43f6-b44b-506862106b66)

<p align="center">
<img src="https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=fff&style=for-the-badge" alt="Neovim" />
<img src="https://img.shields.io/badge/Made%20With%20Lua-2C2D72?logo=lua&logoColor=fff&style=for-the-badge" alt="made with lua" >
</p>
<h1 align="center">Sf.nvim</h1>
<p align="center">A Neovim plugin for Salesforce development, built on the <code>sf</code> CLI</p>

## Contents

- [Features](#features)
- [Intro video](#intro-video-6-min)
- [Requirements](#requirements)
- [Installation](#installation)
- [Getting started](#getting-started)
- [Configuration](#configuration)
- [Default hotkeys](#default-hotkeys)
- [Apex tests and code coverage](#apex-tests-and-code-coverage)
- [Status line](#status-line)
- [Metadata browsing](#metadata-browsing)
- [Refresh sObject definitions](#refresh-sobject-definitions)
- [Terminal](#terminal)
- [Enhanced jump-to-definition](#enhanced-jump-to-definition)
- [Contributing](#contributing)

## Features

- Push and retrieve the current file; create Apex classes, triggers, LWC and Aura bundles
- Rename or delete an Apex class in both the org and locally
- Diff the current file against the target org or any other org
- Run Apex tests (current file, test under cursor, picked tests, whole org), with coverage signs in the sign column
- Run anonymous Apex (file, buffer or selection) and highlighted SOQL
- Browse org metadata and retrieve single items or whole metadata types
- Generate sObject definitions so `apex_ls` completes fields and relationships
- Show the target org and the current file's coverage in your status line
- Run everything in an integrated terminal or through [overseer.nvim](https://github.com/stevearc/overseer.nvim)
- Jump to definition with LSP, falling back to ctags

Every feature is a function in [init.lua](./lua/sf/init.lua), documented in `:h sf.nvim`.

## Intro video (6 min)

[![Feature Intro (6 min)](https://img.youtube.com/vi/MdqPgHIb1pw/0.jpg)](https://www.youtube.com/watch?v=MdqPgHIb1pw)

## Requirements

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`)
- Nvim 0.11 or newer
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main` branch) with the `apex`, `soql`, `sosl` and `sflog` parsers
- Optional: [fzf-lua](https://github.com/ibhagwan/fzf-lua) for the metadata and ctags pickers
- Optional: [universal ctags](https://github.com/universal-ctags/ctags) for [enhanced jump-to-definition](#enhanced-jump-to-definition)
- Optional: [overseer.nvim](https://github.com/stevearc/overseer.nvim) to run commands as overseer tasks

`:checkhealth sf` checks all of these.

<details>
<summary>Example nvim-treesitter setup (lazy.nvim)</summary>

```lua
{
  'nvim-treesitter/nvim-treesitter',
  lazy = false,
  build = ':TSUpdate',
  config = function()
    require('nvim-treesitter').setup {}
    -- No-op if the parsers are already up to date
    require('nvim-treesitter').install({ "apex", "soql", "sosl", "sflog" })
  end,
}
```

On the `main` branch highlighting is no longer enabled automatically; start it
with `vim.treesitter.start()` in an ftplugin file or a `FileType` autocmd.

</details>

![Image 019](https://github.com/user-attachments/assets/aad0ac11-f980-423b-8332-a2b4359fb4ae)

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  'xixiaofinland/sf.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'ibhagwan/fzf-lua', -- optional
  },
  config = function()
    require('sf').setup() -- required
  end,
}
```

With `vim.pack` (Nvim 0.12+):

```lua
vim.pack.add({
  'https://github.com/ibhagwan/fzf-lua', -- optional
  'https://github.com/xixiaofinland/sf.nvim',
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
})

require('fzf-lua').setup()
require('nvim-treesitter').setup()
require('sf').setup() -- required
```

## Getting started

Sf.nvim only works inside a Salesforce project: a folder with `sfdx-project.json`
or `.forceignore` at its root. Its commands and hotkeys register once your cwd or
the current file is inside one. Outside a project, `:SF` tells you why it is
unavailable.

All commands sit under `:SF`, in two levels with tab completion. Type `:SF <Tab>`
to see the categories, then e.g. `:SF test <Tab>` for what a category offers:

![Image 020](https://github.com/user-attachments/assets/725e5d6a-843e-4434-a0c9-a9e72dcb1528)

![Image 021](https://github.com/user-attachments/assets/ab78ef40-6606-4575-b664-a1f905092dc4)

`:SF currentFile push` and `:SF currentFile retrieve` pass further arguments on
to `sf`, e.g. `:SF currentFile push --ignore-conflicts`.

Default hotkeys are **off**. Either turn them on (see
[Default hotkeys](#default-hotkeys)) or map the functions you use:

```lua
local Sf = require('sf')
vim.keymap.set('n', '<leader>ss', Sf.set_target_org, { desc = 'set target_org' })
vim.keymap.set('n', '<leader>sp', Sf.save_and_push, { desc = 'push current file' })
vim.keymap.set('n', '<leader>ta', Sf.run_all_tests_in_this_file, { desc = 'test this file' })
```

## Configuration

Pass options to `setup()`; anything left out keeps its default. The ones most
often changed:

```lua
require('sf').setup({
  -- Turn on the default hotkeys (may override your own mappings)
  enable_hotkeys = false,

  -- Fetch the org list and set target_org when Nvim starts
  fetch_org_list_at_nvim_start = true,

  -- Metadata types offered by `:SF md list`
  types_to_retrieve = { "ApexClass", "ApexTrigger", "StaticResource", "LightningComponentBundle" },

  -- "integrated" or "overseer"
  terminal = "integrated",

  -- Show coverage signs automatically after a test run with coverage
  auto_display_code_sign = true,

  -- Wait time for sf commands, in minutes
  sf_wait_time = 5,
})
```

The full list of options, with their defaults, is in [config.lua](./lua/sf/config.lua).

## Default hotkeys

With `enable_hotkeys = true`, these are mapped (full list in
[config_user_key.lua](./lua/sf/sub/config_user_key.lua)). Project-level keys work
in any buffer; file-level keys only in the filetypes listed in
`hotkeys_in_filetypes`.

| Key                | Function                   | Action                                  |
| ------------------ | -------------------------- | --------------------------------------- |
| `<leader>ss`       | set_target_org             | set target_org                          |
| `<leader>sf`       | fetch_org_list             | fetch/refresh org list                  |
| `<leader><leader>` | toggle_term                | toggle the terminal                     |
| `<leader>sp`       | save_and_push              | push current file                       |
| `<leader>sr`       | retrieve                   | retrieve current file                   |
| `<leader>sd`       | diff_in_target_org         | diff current file against target_org    |
| `<leader>sa`       | run_anonymous_stdin        | run buffer (or selection) as anonymous  |
| `<leader>sq`       | run_highlighted_soql       | run selected text as SOQL (visual mode) |
| `<leader>ta`       | run_all_tests_in_this_file | run all tests in current file           |
| `<leader>tt`       | run_current_test           | run test under cursor                   |
| `<leader>tr`       | repeat_last_tests          | repeat last test run                    |
| `<leader>to`       | open_test_select           | pick tests to run                       |
| `<leader>ct`       | create_ctags               | create ctags file                       |
| `\s`               | toggle_sign                | show/hide coverage signs                |
| `]v` / `[v`        | uncovered_jump_forward/... | jump to next/previous uncovered lines   |

## Apex tests and code coverage

`<leader>ta`, `<leader>tt` and `<leader>to` run tests and report pass/fail.
`<leader>tA` and `<leader>tT` do the same with code coverage: once the run
finishes, covered and uncovered lines get green/red signs next to the line
numbers.

![Image 012](https://github.com/user-attachments/assets/c9539cec-7dcc-48fc-b8e8-929cc1514b07)

- Signs show automatically while `auto_display_code_sign` is `true`; toggle them with `\s` (`require('sf').toggle_sign()`).
- `]v` and `[v` jump between uncovered hunks.

## Status line

`require('sf').get_target_org()` returns the target org, and
`require('sf').covered_percent()` the current Apex file's coverage. The org list
is fetched when Nvim starts and again when you change into another sf project.
Example with lualine.nvim:

```lua
require('lualine').setup {
  sections = {
    lualine_c = { 'filename', function()
      return require('sf').get_target_org() .. "(" .. require('sf').covered_percent() .. ")"
    end },
  },
}
```

![Image 015](https://github.com/user-attachments/assets/3b1ba158-dbcb-4516-a53c-61a824772933)

## Metadata browsing

Both pickers need fzf-lua.

- Single items: `:SF md pull` fetches the org's metadata list, then `:SF md list`
  lets you pick one to retrieve. The types listed come from `types_to_retrieve`.
- Whole types: `:SF mdtype pull` fetches the metadata types, then `:SF mdtype list`
  retrieves every item of the picked type.

## Refresh sObject definitions

Like VS Code's "SFDX: Refresh SObject Definitions": generates Apex stubs under
`.sfdx/tools/sobjects/` so `apex_ls` can complete every sObject in the target
org, custom fields and relationships included.

- `:SF sobject refresh` (all), `:SF sobject refresh STANDARD` or `:SF sobject refresh CUSTOM`
- or `require('sf').refresh_sobjects({ category = "ALL" })`

It runs asynchronously and restarts attached `apex_ls` clients when done (pass
`restart_lsp = false` to opt out). If any part of the refresh fails, the existing
definitions are kept. There is no default hotkey.

## Terminal

![Image 022](https://github.com/user-attachments/assets/bd61e9fc-fa0d-4782-8f2d-68e90dcb0d10)

Commands run in a floating, read-only terminal. Each new command replaces the
previous output, and the terminal pops up when a command finishes while it is
hidden. Toggle it with `:SF term toggle`; cancel with `:SF term cancel`.

Any shell command can run there too:

```lua
vim.keymap.set('n', '<leader>sk', function() require('sf').run('ls -la') end, { desc = 'ls in sf term' })
```

To run commands as [overseer.nvim](https://github.com/stevearc/overseer.nvim)
tasks instead, add it as a dependency and call `setup({ terminal = 'overseer' })`;
`:OverseerToggle` shows the task list.

## Enhanced jump-to-definition

The Apex language server's jump-to-definition misses some cases. With
[universal ctags](https://github.com/universal-ctags/ctags) installed,
`:SF create ctags` writes a tags file in the project root, and `<C-]>` then tries
LSP first and falls back to ctags. `:SF create ctagsAndList` also lists the tags
in fzf-lua.

## Contributing

Open an issue to discuss a change before sending a PR. PRs target the `dev`
branch, and their titles must follow
[Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)
(e.g. `feat: add a new user command`). See [AGENTS.md](./AGENTS.md) for running
the tests and the formatter.

`doc/sf.txt` is generated by [mini.doc](https://github.com/nvim-mini/mini.nvim)
from the `---` comments in [init.lua](./lua/sf/init.lua). Edit the comments, not
the help file, then regenerate it (after `make test` has fetched `deps/`):

```sh
nvim --headless --noplugin -u scripts/minimal_init.lua -c "lua require('sf.util').gen_doc()" -c qa
```

## License

MIT
