-- Sensible editor defaults. Kept in one place so both machines behave the same.

local opt = vim.opt

-- Leader must be set before plugins load (also set again in init.lua, before this
-- file is required, but repeating it here is harmless and keeps this file readable
-- on its own).
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Line numbers
opt.number = true
opt.relativenumber = true

-- Indentation: 2 spaces, expanded (adjust per-filetype later if you want tabs
-- for a specific language, e.g. Makefiles).
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- Visual
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.wrap = false

-- Splits open to the right/below, matching how you read them
opt.splitright = true
opt.splitbelow = true

-- Persistent undo across sessions (undo history survives closing Neovim)
opt.undofile = true
opt.swapfile = false

-- Use the system clipboard for yank/paste by default
opt.clipboard = "unnamedplus"

-- Faster completion / CursorHold events
opt.updatetime = 250

opt.mouse = "a"
