-- ~/.config/nvim/init.lua

-- Read a value from ~/.config/dotf/env.conf
local function read_conf(key)
    local conf = vim.fn.expand("~/.config/dotf/env.conf")
    local f = io.open(conf, "r")
    if not f then return nil end
    for line in f:lines() do
        if not line:match("^%s*#") and not line:match("^%s*$") then
            local k, v = line:match("^([^=]+)=(.*)")
            if k == key then
                f:close()
                return v
            end
        end
    end
    f:close()
    return nil
end

-- General Settings
vim.o.tabstop = 4
vim.o.softtabstop = 4
vim.o.shiftwidth = 4
vim.o.expandtab = true      -- spaces instead of tabs
vim.wo.number = true         -- Show line numbers
vim.o.mouse = 'a'
vim.o.undofile = true
vim.o.termguicolors = true
-- vim.cmd("colorscheme kanagawa")
-- Case insensitive searching UNLESS /C or capital in search
vim.o.ignorecase = true
vim.o.smartcase = true
-- Decrease update time
vim.o.updatetime = 250
vim.wo.signcolumn = 'yes'
-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are required (otherwise wrong leader will be used)
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- force picodoc for .pdoc
vim.filetype.add({
    extension = {
        pdoc = "picodoc",
    },
})


-- Lazy.nvim Bootstrap
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({ 
    "git", "clone", "--filter=blob:none", 
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin Installation
require("lazy").setup({
    { "neovim/nvim-lspconfig" },
    --{ "rebelot/kanagawa.nvim" }, -- Optional: Theme
    { 'navarasu/onedark.nvim' }, -- Theme inspired by Atom
    -- Completion Engine
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "hrsh7th/cmp-nvim-lsp", -- LSP source for nvim-cmp
            "L3MON4D3/LuaSnip",
            "hrsh7th/cmp-buffer",   -- Text in current buffer source
            "hrsh7th/cmp-path",     -- File system paths source
        },
        config = function()
            local cmp = require("cmp")
            cmp.setup({
                formatting = {
                    format = function(entry, vim_item)
                        -- Set the "Menu" column to show the source name
                        vim_item.menu = ({
                            nvim_lsp = "[LSP]",
                            buffer   = "[Buf]",
                            path     = "[Path]",
                        })[entry.source.name]

                        -- If the source is LSP, we can be even more specific
                        if entry.source.name == "nvim-lsp" then
                            local client_name = entry.source.source.client.name
                            vim_item.menu = "[" .. client_name:upper() .. "]"
                        end

                        return vim_item
                    end,
                },
                snippet = {
                    expand = function(args)
                        require('luasnip').lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
                    ['<C-f>'] = cmp.mapping.scroll_docs(4),
                    ['<Tab>'] = cmp.mapping.select_next_item(),
                    ['<S-Tab>'] = cmp.mapping.select_prev_item(),
                    ['<CR>'] = cmp.mapping.confirm({ select = true }),
                    ['<C-j>'] = cmp.mapping(cmp.mapping.select_next_item(), { 'i' }),
                    ['<C-k>'] = cmp.mapping(cmp.mapping.select_prev_item(), { 'i' }),

                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' },
                    { name = 'luasnip' },
                }, {
                        { name = 'buffer' },
                        { name = 'path' },
                    })
            })
        end,
    },
    -- Git related plugins
    { 'tpope/vim-fugitive' },
    { 'tpope/vim-rhubarb' },
    { 'lewis6991/gitsigns.nvim' },
    { 'nvim-lualine/lualine.nvim' }, -- Fancier statusline
    { 'numToStr/Comment.nvim' }, -- "gc" to comment visual regions/lines
    --
    -- Fuzzy Finder (files, lsp, etc)
    { 'nvim-telescope/telescope.nvim', 
        branch = '0.1.x', 
        requires = { 'nvim-lua/plenary.nvim' } 
    },

    -- Fuzzy Finder Algorithm which requires local dependencies to be built. Only load if `make` is available
    { 'nvim-telescope/telescope-fzf-native.nvim', 
        run = 'make', 
        cond = vim.fn.executable 'make' == 1 
    },
    -- Oil file manager
    {
        'stevearc/oil.nvim',
        ---@module 'oil'
        ---@type oil.SetupOpts
        opts = {},
        -- Optional dependencies
        dependencies = { { "nvim-mini/mini.icons", opts = {} } },
        -- dependencies = { "nvim-tree/nvim-web-devicons" }, -- use if you prefer nvim-web-devicons
        -- Lazy loading is not recommended because it is very tricky to make it work correctly in all situations.
        lazy = false,
    },
    read_conf("GEMINI_NVIM") == "true" and {
        "marcinjahn/gemini-cli.nvim",
        cmd = "Gemini",
        keys = {
            { "<leader>a/", "<cmd>Gemini toggle<cr>", desc = "Toggle Gemini CLI" },
            { "<leader>aa", "<cmd>Gemini ask<cr>", desc = "Ask Gemini", mode = { "n", "v" } },
            { "<leader>af", "<cmd>Gemini add_file<cr>", desc = "Add File" },
        },
        dependencies = {
            "folke/snacks.nvim",
        },
        config = true,
    } or nil,
        
    -- Enable the automatic update checker
    checker = { 
        enabled = true,
        notify = true, -- This provides the notification you asked for
        frequency = 86400, -- Check once every 24 hours
    },
    -- Clean up the UI
    change_detection = {
        enabled = true,
        notify = false, -- This avoids "Config reloaded" spam
    },
    -- Ensure we use the latest versions
    install = { missing = true },
})

local capabilities = require('cmp_nvim_lsp').default_capabilities()

-- Ruff for completion, formatting, and linting
vim.lsp.config('ruff', {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'ruff.toml', '.git', '.' },
  capabilities = capabilities,
})
vim.lsp.enable('ruff')

-- Define your custom Ty server configuration
-- In 0.11, this replaces 'lspconfig.configs.ty = ...'
vim.lsp.config('ty', {
    cmd = { 'ty', 'server' },
    filetypes = { 'python' },
    -- Use root_markers (new in 0.11) instead of the old util.root_pattern
    root_markers = { 'pyproject.toml', 'setup.py', '.git' },
    capabilities = capabilities,
})
vim.lsp.enable('ty')

-- Auto-format on save using Ruff
vim.api.nvim_create_autocmd("BufWritePre", {
    pattern = "*.py",
    callback = function()
        vim.lsp.buf.format()
    end,
})

-- Global LSP Keybindings (Modern 0.11 defaults)
-- Neovim 0.11 now has built-in mappings like 'grn' (rename), 'gra' (code action)
-- But you can still add your own via LspAttach
vim.api.nvim_create_autocmd('LspAttach', {
    callback = function(args)
        local opts = { buffer = args.buf }
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
    end,
})

---- Set the keyword program to 'man' for C/C++ files 
-- Enable the built-in man plugin
vim.cmd('runtime! ftplugin/man.lua')

vim.api.nvim_create_autocmd("FileType", {
  pattern = { "c", "cpp" },
  callback = function()
    vim.bo.keywordprg = ":man"
  end,
})

vim.diagnostic.config({
  virtual_text = true, -- Shows message at the end of the line
  signs = true,        -- Keeps the gutter signs
  underline = true,    -- Underlines the actual error
  update_in_insert = false, -- Don't flicker while typing
})

-- set theme
vim.cmd("colorscheme onedark")

-- Set lualine as statusline
-- See `:help lualine.txt`
require('lualine').setup {
  options = {
    icons_enabled = false,
    theme = 'onedark',
    component_separators = '|',
    section_separators = '',
  },
}

-- [[ Configure Telescope ]]
-- See `:help telescope` and `:help telescope.setup()`
require('telescope').setup {
  defaults = {
    mappings = {
      n = {
    	  ['<c-d>'] = require('telescope.actions').delete_buffer
      }, -- n
      i = {
        ['<C-u>'] = false,
        --['<C-d>'] = false,
    	['<C-d>'] = require('telescope.actions').delete_buffer,
        -- ["<C-p>"] = require('telescope.actions').move_selection_previous,
        -- ["<C-n>"] = require('telescope.actions').move_selection_next,
        ["<C-j>"] = require('telescope.actions').move_selection_next,
        ["<C-k>"] = require('telescope.actions').move_selection_previous,
      },
    },
  },
}

-- Enable telescope fzf native, if installed
pcall(require('telescope').load_extension, 'fzf')

-- Enable Comment.nvim
require('Comment').setup()

-- Enable oil filenamager
require("oil").setup({
    -- oil will take over directory buffers
    default_file_explorer = true,
    columns = {
        "icon",
        { "size", align = "right" },
    },
    -- Other config ...
    keymaps = {
        ["h"] = { "actions.show_help", mode = "n" },
        ["q"] = "actions.close",
        ["<Esc>"] = "actions.close",
    },
    win_options = {
        winbar = "%{v:lua.require('oil').get_current_dir()}",
    },
    view_options = {
        show_hidden = true,
    }
})

-- clangd LSP for C dev
vim.lsp.config('clangd', {
  cmd = {
    "clangd",
    "--background-index",
    "--clang-tidy",
    "--header-insertion=iwyu",
    "--completion-style=detailed",
    "--function-arg-placeholders",
  },
  capabilities = {
    -- IMPORTANT: Clangd needs this to avoid "multiple offset encoding" errors
    offsetEncoding = { "utf-16" }, 
  },
  root_markers = { "compile_commands.json", "compile_flags.txt", ".git" },
})
vim.lsp.enable('clangd')

--
-- Keymaps for better default experience
-- See `:help vim.keymap.set()`
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- Remap for dealing with word wrap
vim.keymap.set('n', 'k', "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })
vim.keymap.set('n', 'j', "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })

-- pawe: window navigation

vim.keymap.set('', '<C-J>', '<C-w>j')
vim.keymap.set('', '<C-K>', '<C-w>k') 
vim.keymap.set('', '<C-H>', '<C-w>h') 
vim.keymap.set('', '<C-L>', '<C-w>l') 
vim.keymap.set('n', '<C-_>', '<C-w>_') 
vim.keymap.set('n', '<C-Q>', '<C-w>q') 

-- pawe: escape replacement

vim.keymap.set('i', 'kj', '<Esc>') 
vim.keymap.set('t', 'kj', '<C-\\><C-n>')   -- allow escape to exit insert mode from terminal

-- pawe: colon / semicolon swap

vim.keymap.set('n', ';', ':') 
vim.keymap.set('v', ';', ':') 
vim.keymap.set('n', ':', ';') 
vim.keymap.set('v', ':', ';') 

-- Diagnostic keymaps
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float)
vim.keymap.set('n', '<leader>f', vim.lsp.buf.format, { desc = "Format Buffer" })
-- vim.keymap.set('n', '<leader>g', function() vim.cmd(':%!prettier --parser babel') end, { desc = "Format Buffer with HTML Prettier" })
-- vim.keymap.set('n', '<leader>g', function() vim.cmd(':%!prettier<CR>') end, { buffer = true, desc = "Format Buffer with HTML Prettier" })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist)

-- See `:help telescope.builtin`
vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to telescope to change theme, layout, etc.
  require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer]' })

vim.keymap.set('n', '<leader>sf', require('telescope.builtin').find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>sh', require('telescope.builtin').help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sw', require('telescope.builtin').grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', require('telescope.builtin').live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', require('telescope.builtin').diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', require('telescope.builtin').resume, { desc = '[S]earch [R]esume' })

-- Modern K mapping (Neovim 0.11 style)
vim.keymap.set('n', 'K', function()
  -- 1. Check if there's an active LSP client with hover capabilities
  local has_lsp = false
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  for _, client in ipairs(clients) do
    if client.server_capabilities.hoverProvider then
      has_lsp = true
      break
    end
  end

  if has_lsp then
    vim.lsp.buf.hover()
  else
    -- 2. Fallback to Man pages if no LSP is found (standard C functions)
    local cw = vim.fn.expand('<cword>')
    vim.cmd('vertical Man ' .. cw)
  end
end, { desc = 'LSP Hover or Man Page' })

-- start oil on parent (same as vim-vinegar)
vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })

-- picodoc 
vim.opt.runtimepath:append("~/dev/picodoc/editor/nvim")
vim.lsp.config("picodoc", {
  -- expand to get home dir from ~
  cmd = { vim.fn.expand("~/dev/picodoc/.venv/bin/picodoc-lsp") },
  --cmd = { "~/dev/picodoc/.venv/bin/picodoc-lsp" },
  filetypes = { "picodoc" },
  root_markers = { "picodoc.toml", "pyproject.toml" },
})
vim.lsp.enable("picodoc")
