-- ~/.config/nvim/lua/omarchy/theme.lua
local M = {}

local CURRENT = vim.fn.expand '~/.config/omarchy/current/theme'

local MAP = {
  ['tokyo-night'] = { colorscheme = 'tokyonight', plugin = 'folke/tokyonight.nvim' },
  ['catppuccin'] = { colorscheme = 'catppuccin-macchiato', plugin = 'catppuccin/nvim' },
  ['catppuccin-latte'] = { colorscheme = 'catppuccin-latte', plugin = 'catppuccin/nvim' },
  ['everforest'] = { colorscheme = 'everforest', plugin = 'neanias/everforest' },
  ['gruvbox'] = { colorscheme = 'gruvbox', plugin = 'ellisonleao/gruvbox.nvim' },
  ['kanagawa'] = { colorscheme = 'kanagawa', plugin = 'rebelot/kanagawa.nvim' },
  ['nord'] = { colorscheme = 'nordfox', plugin = 'EdenEast/nightfox.nvim' },
  ['matte-black'] = { colorscheme = 'matteblack', plugin = 'tahayvr/matteblack.nvim' },
  ['ristretto'] = { colorscheme = 'monokai-pro', plugin = 'gthelding/monokai-pro.nvim' },
  ['rose-pine'] = { colorscheme = 'rose-pine', plugin = 'rose-pine/neovim' },
  ['osaka-jade'] = { colorscheme = 'bamboo', plugin = 'ribru17/bamboo.nvim' },
}

local function resolve_theme_dir()
  local target = vim.loop.fs_readlink(CURRENT)
  if not target then
    return nil
  end
  if not target:match '^/' then
    target = vim.fn.fnamemodify(CURRENT, ':h') .. '/' .. target
  end
  return vim.fn.fnamemodify(target, ':p'):gsub('/+$', '')
end

local function theme_key_from_dir(dir)
  return dir and dir:match '([^/]+)$' or nil
end

local function load_plugin(repo_or_name)
  -- lazy.load expects the plugin *name*; derive from repo ("owner/name")
  local name = repo_or_name:match '/(.+)$' or repo_or_name
  pcall(function()
    require('lazy').load { plugins = { name } }
  end)
end

local function apply_for(theme_key)
  local spec = MAP[theme_key]
  if not spec then
    vim.notify("Omarchy: no Neovim mapping for theme '" .. tostring(theme_key) .. "'", vim.log.levels.WARN)
    return
  end

  load_plugin(spec.plugin)

  if spec.colorscheme:match 'latte' then
    vim.o.background = 'light'
  else
    vim.o.background = 'dark'
  end

  local ok, err = pcall(vim.cmd.colorscheme, spec.colorscheme)
  if not ok then
    vim.notify(
      "Omarchy: failed to set colorscheme '" .. spec.colorscheme .. "': " .. tostring(err) .. '\nHint: open :Lazy and install the plugin.',
      vim.log.levels.ERROR
    )
  end
end

function M.apply_now()
  local dir = resolve_theme_dir()
  local key = theme_key_from_dir(dir)
  apply_for(key)
end

function M.start_watching()
  local uv = vim.loop
  local watcher = uv.new_fs_event()
  if not watcher then
    return
  end
  local dir_to_watch = vim.fn.fnamemodify(CURRENT, ':h')
  watcher:start(
    dir_to_watch,
    {},
    vim.schedule_wrap(function()
      M.apply_now()
    end)
  )
  M._watcher = watcher
end

return M
