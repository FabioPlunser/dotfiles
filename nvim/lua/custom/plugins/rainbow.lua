return {
  'HiPhish/rainbow-delimiters.nvim',
  event = 'BufReadPre', -- Load when a buffer is read
  config = function()
    require('rainbow-delimiters.setup').setup {
      -- You can customize options here.
      -- For example, to adjust colors or strategies:
      -- colors = {
      --   "#E06C75", -- red
      --   "#E5C07B", -- yellow
      --   "#98C379", -- green
      --   "#61AFEF", -- blue
      --   "#C678DD", -- purple
      --   "#56B6C2", -- cyan
      -- },
      -- strategy = {
      --   [""] = "global", -- Default strategy for all languages
      --   vim = "local", -- Example: local strategy for vimscript files
      -- },
    }
  end,
}
