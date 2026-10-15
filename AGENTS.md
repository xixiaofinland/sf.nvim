# sf.nvim

Neovim plugin wrapping the Salesforce `sf` CLI. Lua, tested with mini.test: run `make test` (or `make test_file FILE=tests/test_x.lua`) before opening a PR. Test dependencies (`deps/`) are pinned by the `*_REV` variables in the `Makefile`; bump one by editing its rev, and `make test` moves existing clones to it.

## Branches

- `dev` is the integration branch. Every PR targets `dev` (`gh pr create --base dev`) and is squash-merged; the PR title must be a conventional commit (`feat: ...`, `fix: ...`), since it becomes the commit on `dev`.
- `main` is what users install. It only moves by fast-forwarding to `dev` (`git push origin origin/dev:main`) once the maintainer has tried `dev` by hand. Never open a PR against `main` and never commit to it directly; hotfixes go through `dev` too, or the fast-forward breaks.
- GitHub closes an issue from `Closes #N` only when the commit reaches `main`. After merging a PR into `dev`, close its issue by hand with a comment naming the PR, or the tickets it blocks stay blocked. issue-loop (configured in `.issue-loop.conf`) does this itself.

## Agent skills

### Issue tracker

Issues live in GitHub Issues for xixiaofinland/sf.nvim, managed via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default five-role vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one root `GLOSSARY.md` plus `docs/adr/`. See `docs/agents/domain.md`.
