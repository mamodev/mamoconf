vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.wrap = false

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true

vim.opt.smartindent = true

vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.timeoutlen = 400
vim.opt.clipboard = 'unnamedplus'
vim.opt.signcolumn = "yes"

vim.opt.undofile = true

vim.cmd(":hi statusline guibg=NONE")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

local issue_insert_nop = function()
    local seq = vim.api.nvim_replace_termcodes(" <BS>", true, false, true)
    vim.api.nvim_feedkeys(seq, "n", true)
end

local esc_insert_mode = function()
    if pcall(require, "copilot") then
        local cs = require("copilot.suggestion")
        if not vim.b.copilot_suggestion_hidden then
            vim.b.copilot_suggestion_hidden = true
            -- cs.dismiss()
            issue_insert_nop()
            return
        end
    end
    return "<Esc>"
end

vim.keymap.set('n', '-', ":Oil<CR>", { desc = "Open Oil file explorer" })
vim.keymap.set('n', '<leader>o', ':update<CR> :source<CR>')
vim.keymap.set('n', '<leader>w', ':write<CR>')
vim.keymap.set('n', '<leader>q', ':quit<CR>')
vim.keymap.set('i', 'jk', esc_insert_mode, { expr = true, silent = true })
vim.keymap.set('i', '<Esc>', esc_insert_mode, { expr = true, silent = true })

vim.keymap.set('n', '<leader>ff', ':Pick files<CR>')
vim.keymap.set('n', '<leader>fg', ':Pick grep live<CR>')

vim.keymap.set('i', '<D-l>', function()
    if pcall(require, 'copilot') then
        local cp = require('copilot.suggestion')
        if not vim.b.copilot_suggestion_hidden then
            cp.accept_line()
            vim.b.copilot_suggestion_hidden = true
        else
            vim.b.copilot_suggestion_hidden = false
            issue_insert_nop()
        end
    end
end, {expr = true, silent = true})

vim.keymap.set('i', '<D-Bslash>', function()
    if pcall(require, 'copilot') then
        local cp = require('copilot.suggestion')
        if not vim.b.copilot_suggestion_hidden then
            cp.accept_word()
            vim.b.copilot_suggestion_hidden = true
        else
            vim.b.copilot_suggestion_hidden = false
            issue_insert_nop()
        end
    end
end, {expr = true, silent = true})

vim.keymap.set('i', '<D-]>', function()
    if pcall(require, 'copilot') then
        local cp = require('copilot.suggestion')
        if cp.is_visible() then
            cp.next()
        end
    end
end, {expr = true, silent = true})

vim.keymap.set('i', '<D-[>', function()
    if pcall(require, 'copilot') then
        local cp = require('copilot.suggestion')
        if cp.is_visible() then
            cp.prev()
        end
    end
end, {expr = true, silent = true})


-- vim.keymap.set('i', '<S-D-Bslash>', function()
--     if pcall(require, 'copilot') then
--         local cp = require('copilot.suggestion')
--         cp.toggle_auto_trigger()
--     end
-- end, {expr = true, silent = true})

-- vim.keymap.set('n', '<leader>fb', ':Pick buffers<CR>')
-- MiniPick.builtin.cli({ command = { 'echo', 'a\nb\nc' } })
-- vim.keymap.set('n', '<leader>fb', function()
--     if not pcall(require, "mini.pick") then
--         vim.api.nvim_echo({
--             { "Error: mini.pick is not loaded. Please ensure it's installed and configured correctly.", "ErrorMsg" }
--         }, true, {})
--         return
--     end
--
--     local MiniPick = require("mini.pick")
--     local wipeout_cur = function()
--         vim.api.nvim_buf_delete(MiniPick.get_picker_matches().current.bufnr, {})
--     end
--     local buffer_mappings = { wipeout = { char = '<C-d>', func = wipeout_cur } }
--     MiniPick.builtin.buffers({}, { mappings = buffer_mappings })
-- end, { desc = "Pick buffers" })

vim.keymap.set('n', '<leader>fb', function()
  if not pcall(require, 'mini.pick') then
    vim.api.nvim_echo({
      { "Error: mini.pick is not loaded. Please ensure it's installed.", "ErrorMsg" }
    }, true, {})
    return
  end

  local MiniPick = require('mini.pick')

  local function echo_error(msg)
    vim.api.nvim_echo({ { msg, 'ErrorMsg' } }, true, {})
  end

  local function get_cur_bufnr()
    return MiniPick.get_picker_matches().current.bufnr
  end

  -- Delete (bdelete) current buffer; errors if modified or other problem
  local function wipeout_cur()
    local bufnr = get_cur_bufnr()
    local ok, err = pcall(vim.cmd, string.format('bdelete %d', bufnr))
    if not ok then
      echo_error('Error deleting buffer: ' .. err)
    end
  end

  -- Save (write) current buffer
  local function write_cur()
    local bufnr = get_cur_bufnr()
    local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
      vim.cmd.write()
    end)
    if not ok then
      echo_error('Error writing buffer: ' .. err)
    end
  end

  -- Save if modified, then delete
  local function write_and_wipe()
    local bufnr = get_cur_bufnr()
    local modified = vim.api.nvim_buf_get_option(bufnr, 'modified')

    if modified then
      local ok, err = pcall(vim.api.nvim_buf_call, bufnr, function()
        vim.cmd.write()
      end)
      if not ok then
        echo_error('Error writing buffer: ' .. err)
        return
      end
    end

    local ok, err = pcall(vim.cmd, string.format('bdelete %d', bufnr))
    if not ok then
      echo_error('Error deleting buffer: ' .. err)
    end
  end

  local buffer_mappings = {
    wipeout    = { char = '<C-d>', func = wipeout_cur    },
    write      = { char = '<C-w>', func = write_cur      },
    write_wipe = { char = '<C-q>', func = write_and_wipe },
  }

  MiniPick.builtin.buffers({}, { mappings = buffer_mappings })
end, { desc = 'Pick buffers' })

vim.keymap.set({ "n", "x" }, "<leader>fm", function()
    -- Check if 'conform' module is available
    if not pcall(require, "conform") then
        vim.api.nvim_echo({
            { "Error: conform.nvim is not loaded. Please ensure it's installed and configured correctly.", "ErrorMsg" }
        }, true, {})
        return
    end

    -- If conform is loaded, proceed with formatting
    require("conform").format({
        timeout_ms = 500,
        async = false,
    })

end, { desc = "Format file" })


-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({
            { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
            { out,                            "WarningMsg" },
            { "\nPress any key to exit..." },
        }, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    checker = { enabled = true, notify = false },
    spec = {
        {
              'chomosuke/typst-preview.nvim',
              version = '1.*',
              opts = {}, -- lazy.nvim will implicitly calls `setup {}`
        },
        {
            'chipsenkbeil/distant.nvim',
            branch = 'v0.3',
            config = function()
                require('distant'):setup()
            end
        },
        {   "nvim-tree/nvim-web-devicons", opts = {} },
        {
            'stevearc/oil.nvim',
            lazy = false,
            config = function ()
                require('oil').setup()
            end
        },
        {
            'echasnovski/mini.nvim',
            version = '*',
            config = function ()
                require("mini.pick").setup({})
                require("mini.icons").setup({})
            end
        },
        {
            "folke/tokyonight.nvim",
            lazy = false,    -- make sure we load this during startup if it is your main colorscheme
            priority = 1000, -- make sure to load this before all the other start plugins
            config = function()
                -- load the colorscheme here
                vim.cmd([[colorscheme tokyonight]])
            end,
        },
        {
            "zbirenbaum/copilot.lua",
            event = "VeryLazy",
            config = function ()
                require("copilot").setup({
                    suggestion = {
                        enabled = true,
                        auto_trigger = true,
                        trigger_on_accept = false,
                        keymaps = {
                          accept = false,
                          accept_word = false,
                          accept_line = false,
                          next = false,
                          prev = false,
                          dismiss = false,
                        }
                    },
                    panel = {
                        enabled = false
                    },
                    filetypes = {
                        ["*"] = true
                    }
                })

                vim.b.copilot_suggestion_hidden = true

            end,
        },
        {
            --https://github.com/ThePrimeagen/init.lua/blob/master/lua/theprimeagen/lazy/lsp.lua
            "neovim/nvim-lspconfig",

            dependencies = {
                {
                    "folke/lazydev.nvim",
                    ft = "lua", -- only load on lua files
                    opts = {
                        library = {
                            -- See the configuration section for more details
                            -- Load luvit types when the `vim.uv` word is found
                            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                        },
                    },
                },
                "zbirenbaum/copilot-cmp",
                "stevearc/conform.nvim",
                "williamboman/mason.nvim",
                "williamboman/mason-lspconfig.nvim",
                "hrsh7th/cmp-nvim-lsp",
                "hrsh7th/cmp-buffer",
                "hrsh7th/cmp-path",
                "hrsh7th/cmp-cmdline",
                "hrsh7th/nvim-cmp",
                -- "L3MON4D3/LuaSnip",
                -- "saadparwaiz1/cmp_luasnip",
                "j-hui/fidget.nvim",
            },

            config = function()
                require("conform").setup({
                    formatters_by_ft = {
                    }
                })

                local mason        = require("mason")
                local mlsp         = require("mason-lspconfig")
                local lspconfig    = require("lspconfig")
                local cmp          = require("cmp")
                local cmp_nvim_lsp = require("cmp_nvim_lsp")
                local copilot_cmp  = require("copilot_cmp")

                copilot_cmp.setup()
                mason.setup()

                -- 2) Prepare capabilities for nvim-cmp
                local capabilities = cmp_nvim_lsp.default_capabilities()

                -- 3) Tell mason-lspconfig which servers to ensure & how to set them up
                mlsp.setup({
                    ensure_installed = {
                        "pyright", -- Python
                        "clangd",  -- C, C++, CUDA
                        "gopls",   -- Go
                        "lua_ls",  -- Lua
                    },
                    automatic_installation = true,
                    handlers = {
                        -- default handler for all installed servers
                        function(server_name)
                            lspconfig[server_name].setup({
                                capabilities = capabilities,
                                -- You can add an on_attach here later if you want LSP keymaps
                            })
                        end,
                    },
                })
                -- 4) Minimal nvim-cmp setup (no snippets)
                cmp.setup({
                    mapping = cmp.mapping.preset.insert({
                        ["<C-Space>"] = cmp.mapping.complete(),
                        ["<CR>"]      = cmp.mapping.confirm({ select = true }),
                    }),

                    sources = {
                        -- { name = "copilot", group_index = 2 },
                        { name = "nvim_lsp", group_index = 2  },
                        { name = "buffer", group_index = 2 },
                        { name = "path", group_index = 2 },
                    },
                })
            end,

        },

    }
})
