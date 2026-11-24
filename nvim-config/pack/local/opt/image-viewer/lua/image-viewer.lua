-- Image viewer: show the image linked under the cursor in a window next to nvim.
-- A local plugin (pack/local/opt/image-viewer), added with :packadd on the
-- first <leader>iv. Notes: ~/proj/notes/nvim-images.org
--
-- Targets (vim.g.image_viewer):
--   'wpf'   (default) a WPF window, built into Windows; never takes focus
--   'chafa' a Windows Terminal pane drawing sixel; needs chafa (Scoop)
-- While the viewer is open, resting the cursor on an image link shows it.
-- nvim and the viewer talk through files in stdpath('state')/image-viewer.

local M = {}

local state_dir = vim.fn.stdpath('state') .. '/image-viewer'
local state = state_dir .. '/current.txt'
local pid_file = state_dir .. '/viewer.pid'
local exts = { png = true, jpg = true, jpeg = true, gif = true, bmp = true, tif = true, tiff = true }

local function win_path(p) return (p:gsub('/', '\\')) end

-- The plugin root, two levels up from this file (lua/image-viewer.lua), so the
-- scripts are found here and never in another plugin's viewer/ folder.
local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')

local function script(name)
  local path = root .. '/viewer/' .. name
  if not vim.uv.fs_stat(path) then error('image-viewer: ' .. path .. ' not found') end
  return win_path(path)
end

local function is_image(path)
  local ext = path:match('%.(%w+)$')
  return ext ~= nil and exts[ext:lower()] == true
end

local function resolve(path)
  path = vim.fn.expand(path)   -- handles ~
  if not (path:match('^%a:[/\\]') or path:match('^[/\\]')) then
    path = vim.fn.expand('%:p:h') .. '/' .. path
  end
  return vim.fn.fnamemodify(path, ':p')
end

-- An org link [[file:x.png][...]] or [[x.png]] under the cursor, else a bare path.
local function image_at_cursor()
  local line, col = vim.api.nvim_get_current_line(), vim.fn.col('.')
  for s, target, e in line:gmatch('()%[%[([^%]]+)%].-%]()') do
    if col >= s and col < e then
      local path = target:gsub('^file:', ''):gsub('::.*$', '')
      if is_image(path) then return resolve(path) end
    end
  end
  local cfile = vim.fn.expand('<cfile>')
  if cfile ~= '' and is_image(cfile) then
    local path = resolve(cfile)
    if vim.uv.fs_stat(path) then return path end
  end
end

-- The viewer writes its PID on start and removes it on clean exit; check the
-- process too, in case it was closed by hand.
local function running()
  if vim.fn.filereadable(pid_file) == 0 then return false end
  local pid = tonumber((vim.fn.readfile(pid_file)[1] or ''):match('%d+'))
  return pid ~= nil and vim.uv.kill(pid, 0) == 0
end

local last
local saved_updatetime
local group = vim.api.nvim_create_augroup('image_viewer', {})

local function stop_follow()
  vim.api.nvim_clear_autocmds({ group = group })
  if saved_updatetime then vim.o.updatetime = saved_updatetime; saved_updatetime = nil end
end

local function start_follow()
  stop_follow()
  saved_updatetime = vim.o.updatetime
  vim.o.updatetime = 300
  vim.api.nvim_create_autocmd('CursorHold', {
    group = group,
    callback = function()
      local img = image_at_cursor()
      if not img or img == last then return end
      if not running() then return stop_follow() end   -- closed by hand
      last = img
      vim.fn.writefile({ img }, state)
    end,
  })
  vim.api.nvim_create_autocmd('VimLeavePre', {
    group = group,
    -- nvim stops its jobs on exit; give the viewer time to close by itself
    -- (and save its window position) first
    callback = function()
      if not running() then return end
      vim.fn.writefile({ ':quit' }, state)
      vim.wait(500, function() return vim.fn.filereadable(pid_file) == 0 end, 20)
    end,
  })
end

local function launch(cmd, what)
  local job = vim.fn.jobstart(cmd, {
    -- not detach: on Windows a detached powershell exits at once
    on_exit = function(_, code)
      if code ~= 0 and vim.v.exiting == vim.NIL then   -- nvim stops jobs as it exits
        vim.schedule(function() vim.notify(what .. ': exit ' .. code, vim.log.levels.WARN) end)
      end
    end,
  })
  if job <= 0 then vim.notify(what .. ': could not start powershell', vim.log.levels.ERROR) end
end

function M.target()
  return vim.g.image_viewer or 'wpf'
end

function M.open()
  vim.fn.mkdir(state_dir, 'p')
  last = image_at_cursor()
  vim.fn.writefile({ last or '' }, state)
  local dir = win_path(state_dir)
  if M.target() == 'chafa' then
    if vim.fn.executable('chafa') == 0 then
      return vim.notify('image-viewer: chafa not found; use the wpf target', vim.log.levels.ERROR)
    end
    -- wt.exe is an app execution alias that nvim can't run directly, and
    -- cmd.exe jobs mangle their arguments, so start it from PowerShell.
    local ps = ("wt -w 0 sp -V --size 0.4 powershell -NoProfile -File '%s' -StateDir '%s'; "
      .. 'Start-Sleep -Milliseconds 400; wt -w 0 mf left'):format(script('chafa.ps1'), dir)
    launch({ 'powershell', '-NoProfile', '-Command', ps }, 'image-viewer (chafa)')
  else
    launch({ 'powershell', '-NoProfile', '-File', script('wpf.ps1'), '-StateDir', dir },
      'image-viewer (wpf)')
  end
  start_follow()
end

function M.close()
  if running() then vim.fn.writefile({ ':quit' }, state) end
  stop_follow()
end

function M.toggle()
  if running() then M.close() else M.open() end
end

return M
