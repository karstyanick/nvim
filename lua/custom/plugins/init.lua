local CustomPlugins = {}

local function syslist(args)
  local out = vim.fn.systemlist(args)
  if vim.v.shell_error ~= 0 then
    vim.notify(table.concat(out, '\n'), vim.log.levels.ERROR)
    return {}
  end
  return out
end

local function git_root()
  local out = syslist { 'git', 'rev-parse', '--show-toplevel' }
  return out[1]
end

local function fname(f)
  return vim.fn.fnameescape(f)
end

local function changed_files()
  local root = git_root()
  if not root or root == '' then
    vim.notify('Not inside a Git repo.', vim.log.levels.ERROR)
    return {}
  end

  local files = {}

  -- Unstaged changes
  for _, f in ipairs(syslist { 'git', 'diff', '--name-only' }) do
    table.insert(files, f)
  end

  -- Untracked files
  for _, f in ipairs(syslist { 'git', 'ls-files', '--others', '--exclude-standard' }) do
    table.insert(files, f)
  end

  -- Absolutize, filter unreadable
  local ok = {}
  for _, rel in ipairs(files) do
    if rel ~= '' then
      local abs = vim.fs.joinpath(root, rel)
      if vim.fn.filereadable(abs) == 1 then
        table.insert(ok, abs)
      end
    end
  end
  return ok
end

local function open(files)
  if #files == 0 then
    vim.notify('No changed files.', vim.log.levels.INFO)
    return
  end

  -- Add all as *listed* buffers
  for _, f in ipairs(files) do
    vim.cmd('badd ' .. fname(f))
  end

  -- Jump to the first
  vim.cmd('buffer ' .. fname(files[1]))
end

CustomPlugins.open_changed = function(_)
  open(changed_files())
end

return CustomPlugins
