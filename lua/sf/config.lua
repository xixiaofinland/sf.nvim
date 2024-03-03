local Cfg = {}

local default_cfg = {
  types_to_retrieve = {
    "ApexClass",
    "ApexTrigger",
    "StaticResource",
    "LightningComponentBundle"
  }
}

local apply_config = function(opt)
  Cfg.config = vim.tbl_deep_extend('force', default_cfg, opt)
end

Cfg.setup = function(opt)
  opt = opt or {}
  vim.validate({ config = { opt, 'table', true } })
  apply_config(opt)
end

return Cfg
