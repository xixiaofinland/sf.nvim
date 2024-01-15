# Sf.nvim

Offer basic functionalities for Apex to interact with Salesforce org

## Modules

- `sf.org` configure target org
- `sf.term` establish an integrated terminal
- `sf.ts` run test

## Usage

At the moment maybe the best way is to take a peek at [my latest
keybindings](https://github.com/xixiaofinland/dotfiles/blob/main/.config/nvim/after/ftplugin/apex.lua)

If the current buff is a Test Apex file, `require("sf.ts").open` opens a temp buffer which lists all tests.

In this temp buffer, 
- use `t` to toggle select/unselect tests
- use `cc` to run the select tests in the integrated terminal

`require("sf.term").repeatLastTests` runs the last selected tests

```
nmap('<leader>sto', require("sf.ts").open, "[T]est [O]pen Buf Select")
nmap('<leader>str', require("sf.term").repeatLastTests, "[T]est [R]epeat")
```

## Video demostration

[![Demostration](https://img.youtube.com/vi/qrJmjJFPALY/0.jpg)](https://youtu.be/qrJmjJFPALY?si=QRq_fNxXfP2ThcBy&t=846)
