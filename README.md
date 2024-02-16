# Sf.nvim

Offer common functionalities for Salesforce development

## Usage

Maybe the best way is to take a peek at [my latest
keybindings](https://github.com/xixiaofinland/dotfiles/blob/main/.config/nvim/after/ftplugin/apex.lua)

## Modules

- `sf.org` target org
- `sf.term` integrated terminal
- `sf.ts` treesitter
- `sf.test` Apex test

## relative new features

### Multi-select tests to run
If the current buffer is a Test Apex file, `require("sf.test").open` opens a temporary buffer which lists all tests.

### Re-run the previous selection in the temporary buffer
`require("sf.term").repeatLastTests` runs the last selected tests


## Other video (out-dated)

Made on 13-01-2024

[![Demostration](https://img.youtube.com/vi/qrJmjJFPALY/0.jpg)](https://youtu.be/qrJmjJFPALY?si=QRq_fNxXfP2ThcBy&t=846)
