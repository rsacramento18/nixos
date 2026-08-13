local darkTheme = false
function ToggleTheme()
  if darkTheme == true then
    require('mini.hues').setup({
      background = '#14161B',
      foreground = '#E1E1E1',
      n_hues = 8,
      saturation = 'lowmedium',
      accent = 'fg',
    })
    darkTheme = false
  else
    require('mini.hues').setup({
      background = '#E8E1DC',
      foreground = '#000000',
      n_hues = 8,
      saturation = 'high',
      accent = 'fg',
    })
    darkTheme = true
  end
end

vim.api.nvim_create_user_command('ToggleTheme', function()
  ToggleTheme()
end, {})

return {
  {
    'echasnovski/mini.hues',
    version = '*',
    config = function()
      require('mini.hues').setup({
        background = '#14161B',
        foreground = '#E1E1E1',
        n_hues = 8,
        saturation = 'lowmedium',
        accent = 'fg',
      })
    end,
  },
}
