# Test dependencies are pinned so local runs and CI test the same code.
# To bump one, set its rev to the new commit (e.g. the output of
# `git ls-remote <url> HEAD`) and run `make test`; existing clones are
# moved to the pinned commit automatically.
MINI_NVIM_URL := https://github.com/nvim-mini/mini.nvim
MINI_NVIM_REV := e3f2349a65143ff062f0b70ee9d68d8ce35c7059
NVIM_TREESITTER_URL := https://github.com/nvim-treesitter/nvim-treesitter.git
NVIM_TREESITTER_REV := ca581c3436fc2b236847f5b739ebc263739e5ca6
# Keep in step with the apex/soql/sosl revision in nvim-treesitter's
# lua/nvim-treesitter/parsers.lua, so tests parse what users get.
SFAPEX_URL := https://github.com/aheber/tree-sitter-sfapex
SFAPEX_REV := da568eee10ce4724a40f368b2b7e795dacb4f1ba
PARSERS := apex soql sosl

# Run all test files
test: deps
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file: deps
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

# Regenerate doc/sf.txt and doc/tags from the `---` comments in lua/sf/init.lua
# with the pinned mini.doc. CI runs it on every push to dev and commits the
# result, so this is only for previewing the help locally.
doc: deps
	nvim --headless --noplugin -i NONE -u ./scripts/minimal_init.lua -c "lua require('sf.util').gen_doc()" -c qa

# Record every fixture of the sf fake, scrubbed, from a throwaway scratch org
# that it creates from the Dev Hub aliased $(DEVHUB) and deletes again. Each run
# uses one of the Dev Hub's daily scratch orgs; see tests/helpers.lua.
DEVHUB ?= devhub

record-fixtures:
	nvim -l scripts/record_fixtures.lua '$(DEVHUB)'

# Lua formatting, per .stylua.toml; CI runs fmt-check.
STYLUA_PATHS := lua tests scripts

fmt:
	stylua $(STYLUA_PATHS)

fmt-check:
	stylua --check $(STYLUA_PATHS)

# Clone a dependency into $(1) from $(2) if missing, then check out commit $(3),
# fetching it only when the clone doesn't have it yet.
define pin
	@[ -d $(1) ] || git clone --filter=blob:none $(2) $(1)
	@[ "$$(git -C $(1) rev-parse HEAD 2>/dev/null)" = "$(3)" ] || { \
		git -C $(1) cat-file -e $(3)^{commit} 2>/dev/null || git -C $(1) fetch --filter=blob:none origin $(3); \
		git -C $(1) -c advice.detachedHead=false checkout --detach $(3); \
	}
endef

deps:
	@mkdir -p deps
	$(call pin,deps/mini.nvim,$(MINI_NVIM_URL),$(MINI_NVIM_REV))
	$(call pin,deps/nvim-treesitter,$(NVIM_TREESITTER_URL),$(NVIM_TREESITTER_REV))
	$(call pin,deps/tree-sitter-sfapex,$(SFAPEX_URL),$(SFAPEX_REV))
	@$(MAKE) --no-print-directory parsers

# Compiled straight from the grammar's generated C, which needs only a C
# compiler: nvim-treesitter's installer requires Neovim 0.12, and CI also
# tests 0.11. A run in a fresh make sees the sources the pin above checked out;
# a rev bump rewrites them, so the parsers rebuild.
parsers: $(PARSERS:%=deps/parsers/parser/%.so)

# scanner.c is optional; none of the three grammars has one today.
deps/parsers/parser/%.so: deps/tree-sitter-sfapex/%/src/parser.c
	@mkdir -p $(@D)
	cc -shared -fPIC -O2 -I$(<D) $< $(wildcard $(<D)/scanner.c) -o $@

.PHONY: test test_file doc record-fixtures fmt fmt-check deps parsers
