# Sf.nvim

Offer basic functionalities for Apex to interact with Salesforce org

## Modules

- `sf.org` configure target org
- `sf.term` establish an integrated terminal
- `sf.ts` run test

## Hotkeys example

```
nmap('<leader>ss', require("sf.org").set, "[s]et target_org current workspace")
nmap('<leader>sS', require("sf.org").setGlobal, "[S]et target_org globally")
nmap('<leader>sf', require("sf.org").fetch, "[F]etch orgs info")

nmap('<leader>t', require("sf.term").toggle, "[T]erminal toggle")
nmap('<leader>sp', require("sf.term").saveAndPush, "[P]ush current file")
nmap('<leader>sr', require("sf.term").retrieve, "[R]etrieve current file")
nmap('<leader>sc', require("sf.term").cancel, "[C]ancel current running command")
nmap('<leader>sta', require("sf.term").runAllTestsInCurrentFile, "[T]est [A]ll")
nmap('<leader>stt', require("sf.term").runCurrentTest, "[T]est [T]his under cursor")
```

## Video demostration

[![Demostration](https://img.youtube.com/vi/qrJmjJFPALY/0.jpg)](https://youtu.be/qrJmjJFPALY?si=QRq_fNxXfP2ThcBy&t=846)
