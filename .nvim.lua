-- Local Neovim configuration for nitro_kit/starter
-- Disable rubyfmt and enable rubocop for this project

-- Override conform configuration to disable rubyfmt for Ruby files
local conform = require("conform")
local current_opts = conform.get_formatters_for_buffer or {}

-- Update formatters to remove rubyfmt from Ruby files
conform.setup({
  formatters_by_ft = vim.tbl_deep_extend("force", current_opts.formatters_by_ft or {}, {
    ruby = {},  -- Disable all formatters for Ruby files in this project
    eruby = { "erb_format", "rustywind" }, -- Keep erb_format and rustywind for ERB files
  }),
})

-- Configure rubocop as linter via nvim-lint
pcall(function()
  local lint = require("lint")
  
  -- Add rubocop linter for Ruby files
  lint.linters_by_ft = vim.tbl_extend("force", lint.linters_by_ft or {}, {
    ruby = { "rubocop" },
  })

  -- Auto-run linting on various events
  local lint_augroup = vim.api.nvim_create_augroup("local_lint", { clear = true })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
    group = lint_augroup,
    pattern = "*.rb",
    callback = function()
      lint.try_lint()
    end,
  })
end)