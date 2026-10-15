# Test dependencies are pinned so local runs and CI test the same code.
# To bump one, set its rev to the new commit (e.g. the output of
# `git ls-remote <url> HEAD`) and run `make test`; existing clones are
# moved to the pinned commit automatically.
MINI_NVIM_URL := https://github.com/nvim-mini/mini.nvim
MINI_NVIM_REV := e3f2349a65143ff062f0b70ee9d68d8ce35c7059
NVIM_TREESITTER_URL := https://github.com/nvim-treesitter/nvim-treesitter.git
NVIM_TREESITTER_REV := ca581c3436fc2b236847f5b739ebc263739e5ca6

# Run all test files
test: deps
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run()"

# Run test from file at `$FILE` environment variable
test_file: deps
	nvim --headless --noplugin -u ./scripts/minimal_init.lua -c "lua MiniTest.run_file('$(FILE)')"

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

.PHONY: test test_file deps
