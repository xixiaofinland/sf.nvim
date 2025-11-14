local M = {}

M.set_default_hotkeys = function()
  local nmap = function(keys, func, desc)
    if desc then
      desc = desc .. " [Sf]"
    end
    vim.keymap.set("n", keys, func, { buffer = true, desc = desc })
  end

  local Sf = require("sf")

  -- Common hotkeys for all files;
  nmap("<leader>ss", Sf.set_target_org, "set target_org current workspace")
  nmap("<leader>sS", Sf.set_global_target_org, "set global target_org")
  nmap("<leader>sf", Sf.fetch_org_list, "fetch orgs info")
  nmap("<leader>ml", Sf.list_md_to_retrieve, "metadata listing")
  nmap("<leader>mtl", Sf.list_md_type_to_retrieve, "metadata-type listing")
  nmap("<leader><leader>", Sf.toggle_term, "terminal toggle")
  nmap("<C-c>", Sf.cancel, "cancel running command")
  nmap("<leader>s-", Sf.go_to_sf_root, "cd into root")
  nmap("<leader>ct", Sf.create_ctags, "create ctag file in project root")
  nmap("<leader>ft", Sf.create_and_list_ctags, "fzf list updated ctags")
  nmap("<leader>so", Sf.org_open, "open target_org")

  -- Hotkeys for metadata files only;
  if vim.tbl_contains(vim.g.sf.hotkeys_in_filetypes, vim.bo.filetype) then
    nmap("<leader>sO", Sf.org_open_current_file, "open file in target_org")
    nmap("<leader>sd", Sf.diff_in_target_org, "diff in target_org")
    nmap("<leader>sD", Sf.diff_in_org, "diff in org...")
    nmap("<leader>ma", Sf.retrieve_apex_under_cursor, "apex under cursor retrieve")
    nmap("<leader>sp", Sf.save_and_push, "push current file")
    nmap("<leader>sr", Sf.retrieve, "retrieve current file")
    nmap("<leader>sR", Sf.rename_apex_class_remote_and_local, "rename current apex from org and local")
    nmap("<leader>sX", Sf.delete_current_apex_remote_and_local, "delete current apex from org and local")
    nmap("<leader>sa", Sf.run_anonymous, "run this file anonymously")

    vim.keymap.set("x", "<leader>sq", Sf.run_highlighted_soql, { buffer = true, desc = "SOQL run highlighted text" })

    nmap("<leader>ta", Sf.run_all_tests_in_this_file, "test all in this file")
    nmap("<leader>tA", Sf.run_all_tests_in_this_file_with_coverage, "test all with coverage info")
    nmap("<leader>tt", Sf.run_current_test, "test this under cursor")
    nmap("<leader>tT", Sf.run_current_test_with_coverage, "test this under cursor with coverage info")
    nmap("<leader>to", Sf.open_test_select, "open test select buf")
    nmap("\\s", Sf.toggle_sign, "toggle signs for code coverage")
    nmap("<leader>tr", Sf.repeat_last_tests, "repeat last test")
    nmap("<leader>cc", Sf.copy_apex_name, "copy apex name")
    nmap("<leader>cc", Sf.copy_apex_name, "copy apex name")
    nmap("[v", Sf.uncovered_jump_backward, "jump to previous uncovered sign icon line")
    nmap("]v", Sf.uncovered_jump_forward, "jump to next uncovered sign icon line")
  end
end

return M
