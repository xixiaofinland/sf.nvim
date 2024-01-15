# Sf.nvim

Offer basic functionalities for Apex to interact with Salesforce org

## Notice

This is a personal project I use to learn to create Nvim plugins.
Due to its rapid design change and code refactory, breaking change is expected.

Please fix the pulled commit version in your plugin manager if you expect it
working stable for you.

## Modules

- `sf.org` configure target org
- `sf.term` establish an integrated terminal
- `sf.ts` run test

## Usage

Maybe the best way is to take a peek at [my latest
keybindings](https://github.com/xixiaofinland/dotfiles/blob/main/.config/nvim/after/ftplugin/apex.lua)

## relative new features

```
nmap('<leader>sto', require("sf.ts").open, "[T]est [O]pen Buf Select")
nmap('<leader>str', require("sf.term").repeatLastTests, "[T]est [R]epeat")
```

### Multi-select tests to run
If the current buffer is a Test Apex file, `require("sf.ts").open` opens a temporary buffer which lists all tests.

In this temp buffer, 
- use `t` to toggle select/unselect tests
- use `cc` to run the select tests in the integrated terminal

### Re-run the previous selection in the temporary buffer
`require("sf.term").repeatLastTests` runs the last selected tests


## Video demostration

Made on 13-01-2024

[![Demostration](https://img.youtube.com/vi/qrJmjJFPALY/0.jpg)](https://youtu.be/qrJmjJFPALY?si=QRq_fNxXfP2ThcBy&t=846)
