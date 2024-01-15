# Sf.nvim

Offer basic functionalities for Apex to interact with Salesforce org

## Notice

This is a personal project I use to learn to create Nvim plugins.
Due to its rapid design change and code refactory, breaking change is expected.

Please fix the pulled commit version in your plugin manager if you expect it
working stable for you.

## Demostration

https://github.com/xixiaofinland/sf.nvim/assets/13655323/f433854d-a710-4a7e-9993-867b2271b88d

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

In this temp buffer, 
- use `t` to toggle select/unselect tests
- use `cc` to run the select tests in the integrated terminal

### Re-run the previous selection in the temporary buffer
`require("sf.term").repeatLastTests` runs the last selected tests


## Other video (out-dated)

Made on 13-01-2024

[![Demostration](https://img.youtube.com/vi/qrJmjJFPALY/0.jpg)](https://youtu.be/qrJmjJFPALY?si=QRq_fNxXfP2ThcBy&t=846)
