-- lazygit in a floating window: <leader>lg
return {
  'kdheepak/lazygit.nvim',
  cmd = {
    'LazyGit',
    'LazyGitConfig',
    'LazyGitCurrentFile',
    'LazyGitFilter',
    'LazyGitFilterCurrentFile',
  },
  dependencies = {
    'nvim-lua/plenary.nvim',
  },
  keys = {
    { '<leader>lg', '<cmd>LazyGit<cr>', desc = '[L]azy[G]it' },
    { '<leader>lf', '<cmd>LazyGitCurrentFile<cr>', desc = '[L]azygit current [F]ile' },
  },
}
