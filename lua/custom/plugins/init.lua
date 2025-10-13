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

local function resolve_ref(ref)
  local ok = syslist { 'git', 'rev-parse', '--verify', '--quiet', ref }
  if ok[1] and ok[1] ~= '' then
    return ref
  end
  local origin_ref = 'origin/' .. ref
  local ok2 = syslist { 'git', 'rev-parse', '--verify', '--quiet', origin_ref }
  if ok2[1] and ok2[1] ~= '' then
    return origin_ref
  end
  return nil
end

local function changed_files(ref)
  local root = git_root()
  if not root or root == '' then
    vim.notify('Not inside a Git repo.', vim.log.levels.ERROR)
    return {}
  end

  local files = {}
  local args

  if ref then
    local base = resolve_ref(ref)
    if not base then
      vim.notify('Cannot resolve ref "' .. ref .. '" or "origin/' .. ref .. '".', vim.log.levels.ERROR)
      return {}
    end
    args = { 'git', 'diff', '--name-only', base }
  else
    args = { 'git', 'diff', '--name-only' }
  end

  -- Changed (vs ref or local unstaged)
  for _, f in ipairs(syslist(args)) do
    table.insert(files, f)
  end

  -- Untracked
  for _, f in ipairs(syslist { 'git', 'ls-files', '--others', '--exclude-standard' }) do
    table.insert(files, f)
  end

  for _, f in ipairs(syslist { 'git', 'diff', '--name-only', '--cached' }) do
    table.insert(files, f)
  end

  -- Absolutize & filter unreadable
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
  for _, f in ipairs(files) do
    vim.cmd('badd ' .. fname(f))
  end
  vim.cmd('buffer ' .. fname(files[1]))
end

-- Open local changed files
CustomPlugins.open_changed = function(_, ref)
  open(changed_files(ref))
end

return CustomPlugins
