-- External dependencies:
--   [mandatory] tree-sitter-cli  (yay -S tree-sitter-cli)   nvim-treesitter: compile parsers
--   [mandatory] claude CLI        (claude.ai/code)            ThePrimeagen/99: ClaudeCodeProvider
--   [mandatory] git               (yay -S git)                lazy.nvim bootstrap + harpoon
--   [optional]  typst             (yay -S typst)              typst-preview.nvim
--   [optional]  distant binary    (cargo install distant)     distant.nvim remote editing
--   [optional]  node + npm        (yay -S nodejs npm)         mason: JS-based LSP servers
--   [optional]  python3           (yay -S python)             mason: Python-based LSP servers
--   [optional]  unzip / tar       (yay -S unzip)              mason: extract downloaded packages

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
vim.opt.signcolumn = "yes"

vim.opt.undofile = true

vim.cmd(":hi statusline guibg=NONE")

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.clipboard = 'unnamedplus'

if vim.fn.has('wsl') == 1 and vim.fn.executable('/mnt/c/Windows/System32/clip.exe') == 1 then
    vim.g.clipboard = {
        name = 'WslClipboard',
        copy = {
            ['+'] = '/mnt/c/Windows/System32/clip.exe',
            ['*'] = '/mnt/c/Windows/System32/clip.exe',
        },
        paste = {
            ['+'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
            ['*'] = 'powershell.exe -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))',
        },
        cache_enabled = 0,
    }
elseif vim.fn.has('wsl') == 1 or vim.env.SSH_TTY then
    vim.g.clipboard = 'osc52'
end

vim.api.nvim_create_user_command("ClangdDocker", function()
  vim.ui.input({ prompt = "Container project path: ", default = "/project/ARES" }, function(container_root)
    if not container_root or container_root == "" then return end
    -- Dynamically find the host root based on your project markers
    local host_root = vim.fs.root(0, { ".git", "compile_commands.json" }) or vim.fn.getcwd()

    vim.lsp.config("clangd", {
      cmd = { "clangd-docker" },
      root_markers = { "compile_commands.json", ".git" },
      settings = { path_mappings = { [container_root] = host_root } }
    })
    vim.lsp.enable("clangd")
    print("Bridged: " .. host_root .. "  " .. container_root)
  end)
end, { desc = "Dynamic Clangd Docker Bridge" })


vim.api.nvim_create_autocmd("FileType", {
    pattern = "qf",
    callback = function()
        vim.opt_local.wrap = true
    end,
})

local autosave_enabled = false
local autosave_group = vim.api.nvim_create_augroup("AutosaveGroup", { clear = true })

vim.api.nvim_create_user_command("Autosave", function()
  if autosave_enabled then
    vim.api.nvim_clear_autocmds({ group = autosave_group, buffer = 0 })
    autosave_enabled = false
    print("Autosave disabled for current buffer")
  else
    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      group = autosave_group,
      buffer = 0,
      callback = function()
        vim.cmd("silent! write")
      end,
    })
    autosave_enabled = true
    print("Autosave enabled for current buffer")
  end
end, {})

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
vim.keymap.set('n', '<leader>q',  ':bdelete<CR>',    { desc = "Close buffer" })
vim.keymap.set('n', '<leader>qa', ':qa!<CR>',        { desc = "Force quit nvim" })
vim.keymap.set('n', '<leader>sv', ':vsplit<CR>',     { desc = "Vertical split" })
vim.keymap.set('n', '<leader>sh', ':split<CR>',      { desc = "Horizontal split" })
vim.keymap.set('n', '<leader>se', '<C-w>=',          { desc = "Equalize splits" })
vim.keymap.set('n', '<leader>sx', ':close<CR>',      { desc = "Close split" })
vim.keymap.set('n', '<leader>gd', vim.lsp.buf.definition)
vim.keymap.set('n', '<leader>gr', function()
    require('mini.extra').pickers.lsp({ scope = 'references' })
end, { desc = "LSP references" })
vim.keymap.set('n', '<leader>gi', vim.lsp.buf.implementation,      { desc = "LSP implementation" })
vim.keymap.set('n', '<leader>gt', vim.lsp.buf.type_definition,     { desc = "LSP type definition" })
vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename,              { desc = "LSP rename" })
vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action,         { desc = "LSP code action" })
vim.keymap.set('n', 'K',          vim.lsp.buf.hover,               { desc = "LSP hover docs" })
vim.keymap.set('n', '<leader>ds', function()
    require('mini.extra').pickers.lsp({ scope = 'document_symbol' })
end, { desc = "LSP document symbols" })
vim.keymap.set('n', '<leader>ws', function()
    require('mini.extra').pickers.lsp({ scope = 'workspace_symbol' })
end, { desc = "LSP workspace symbols" })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev,                { desc = "Prev diagnostic" })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next,                { desc = "Next diagnostic" })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float,        { desc = "Diagnostic float" })
-- vim.keymap.set('i', 'jk', esc_insert_mode, { expr = true, silent = true })
-- vim.keymap.set('i', '<Esc>', esc_insert_mode, { expr = true, silent = true })

vim.keymap.set('n', '<leader>ff', function()
    local MiniPick = require("mini.pick")
    local in_git = vim.fn.system("git rev-parse --is-inside-work-tree 2>/dev/null"):gsub("\n", "") == "true"
    if not in_git then
        MiniPick.builtin.files()
        return
    end
    local show = function(buf_id, items, query, opts)
        MiniPick.default_show(buf_id, items, query, opts)
        if not pcall(require, "mini.icons") then return end
        local MiniIcons = require("mini.icons")
        local ns = vim.api.nvim_create_namespace("pick_icons")
        vim.api.nvim_buf_clear_namespace(buf_id, ns, 0, -1)
        for i, item in ipairs(items) do
            local icon, hl = MiniIcons.get("file", tostring(item))
            vim.api.nvim_buf_set_extmark(buf_id, ns, i - 1, 0, {
                virt_text = {{ icon .. " ", hl }},
                virt_text_pos = "inline",
            })
        end
    end
    MiniPick.start({
        source = {
            items = vim.fn.systemlist("git ls-files --recurse-submodules"),
            name = "Files",
            show = show,
        }
    })
end)
vim.keymap.set('n', '<leader>fg', ':Pick grep live<CR>')
vim.keymap.set('n', '<leader>fs', function()
    require("mini.pick").builtin.grep_live()
end, { desc = "Fuzzy grep cwd" })
vim.keymap.set('n', '<leader>fh', function()
    local MiniPick = require("mini.pick")
    local bufnr = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    local items = {}
    for i, line in ipairs(lines) do
        table.insert(items, { text = string.format("%4d: %s", i, line), lnum = i })
    end
    MiniPick.start({
        source = {
            items = items,
            name = "Buffer lines",
            choose = function(item)
                vim.api.nvim_win_set_cursor(0, { item.lnum, 0 })
            end,
        },
    })
end, { desc = "Fuzzy find in current file" })

-- vim.keymap.set('i', '<D-l>', function()
--     if pcall(require, 'copilot') then
--         local cp = require('copilot.suggestion')
--         if not vim.b.copilot_suggestion_hidden then
--             cp.accept_line()
--             vim.b.copilot_suggestion_hidden = true
--         else
--             vim.b.copilot_suggestion_hidden = false
--             issue_insert_nop()
--         end
--     end
-- end, {expr = true, silent = true})
--
-- vim.keymap.set('i', '<D-Bslash>', function()
--     if pcall(require, 'copilot') then
--         local cp = require('copilot.suggestion')
--         if not vim.b.copilot_suggestion_hidden then
--             cp.accept_word()
--             vim.b.copilot_suggestion_hidden = true
--         else
--             vim.b.copilot_suggestion_hidden = false
--             issue_insert_nop()
--         end
--     end
-- end, {expr = true, silent = true})
--
-- vim.keymap.set('i', '<D-]>', function()
--     if pcall(require, 'copilot') then
--         local cp = require('copilot.suggestion')
--         if cp.is_visible() then
--             cp.next()
--         end
--     end
-- end, {expr = true, silent = true})
--
-- vim.keymap.set('i', '<D-[>', function()
--     if pcall(require, 'copilot') then
--         local cp = require('copilot.suggestion')
--         if cp.is_visible() then
--             cp.prev()
--         end
--     end
-- end, {expr = true, silent = true})
--

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
    if vim.api.nvim_buf_get_option(bufnr, 'modified') then
      echo_error('Buffer has unsaved changes. Save first.')
      return
    end
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
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate",
            dependencies = { "nvim-treesitter/nvim-treesitter-textobjects" },
            config = function()
                -- v1.x: setup() only accepts install_dir
                require("nvim-treesitter").setup()

                local install = require("nvim-treesitter.install")

                -- install common parsers upfront
                install.install({ "c", "cpp", "lua", "python", "bash", "vim", "vimdoc" })

                -- auto-install + highlight on every buffer open
                local ts_ignored_ft = { toggleterm = true, TelescopePrompt = true, minifiles = true, oil = true, harpoon = true }
                vim.api.nvim_create_autocmd("FileType", {
                    callback = function(ev)
                        if ts_ignored_ft[vim.bo[ev.buf].filetype] then return end
                        local lang = vim.treesitter.language.get_lang(vim.bo[ev.buf].filetype)
                        if lang then
                            pcall(install.install, { lang })
                            pcall(vim.treesitter.start, ev.buf, lang)
                        end
                    end,
                })

                -- textobjects: configure defaults
                require("nvim-treesitter-textobjects").setup({
                    select = { lookahead = true },
                    move   = { set_jumps = true },
                })

                -- select text objects
                local sel = require("nvim-treesitter-textobjects.select")
                local keymaps = {
                    ["af"] = "@function.outer",
                    ["if"] = "@function.inner",
                    ["ac"] = "@class.outer",
                    ["ic"] = "@class.inner",
                    ["ap"] = "@parameter.outer",
                    ["ip"] = "@parameter.inner",
                }
                for key, query in pairs(keymaps) do
                    vim.keymap.set({ "x", "o" }, key, function()
                        sel.select_textobject(query, "textobjects")
                    end)
                end

                -- move between text objects
                local mov = require("nvim-treesitter-textobjects.move")
                vim.keymap.set("n", "]f", function() mov.goto_next_start("@function.outer",     "textobjects") end)
                vim.keymap.set("n", "]c", function() mov.goto_next_start("@class.outer",         "textobjects") end)
                vim.keymap.set("n", "]F", function() mov.goto_next_end("@function.outer",        "textobjects") end)
                vim.keymap.set("n", "[f", function() mov.goto_previous_start("@function.outer",  "textobjects") end)
                vim.keymap.set("n", "[c", function() mov.goto_previous_start("@class.outer",     "textobjects") end)
                vim.keymap.set("n", "[F", function() mov.goto_previous_end("@function.outer",    "textobjects") end)
                vim.keymap.set("n", "]b", function() mov.goto_next_start("@block.outer",         "textobjects") end)
                vim.keymap.set("n", "[b", function() mov.goto_previous_start("@block.outer",     "textobjects") end)
                vim.keymap.set("n", "]a", function() mov.goto_next_start("@parameter.inner",     "textobjects") end)
                vim.keymap.set("n", "[a", function() mov.goto_previous_start("@parameter.inner", "textobjects") end)
            end,
        },
        {
            "ThePrimeagen/99",
            config = function()
                local _99 = require("99")
                _99.setup({
                    provider = _99.Providers.ClaudeCodeProvider,
                    model = "claude-sonnet-4-6",
                    md_files = { "AGENT.md" },
                })
                vim.keymap.set("n", "<leader>9s", function() _99.search() end, { desc = "99: AI search" })
                vim.keymap.set("v", "<leader>9v", function() _99.visual() end, { desc = "99: AI visual transform" })
                vim.keymap.set("n", "<leader>9x", function() _99.stop_all_requests() end, { desc = "99: stop requests" })
                vim.keymap.set("n", "<leader>9o", function() _99.open() end, { desc = "99: open last result" })
                vim.keymap.set("n", "<leader>9l", function() _99.view_logs() end, { desc = "99: view request logs" })
                vim.keymap.set("v", "<leader>9e", function()
                    local file = vim.fn.expand("%:.")
                    local ft = vim.bo.filetype
                    local start_pos = vim.fn.getpos("'<")
                    local end_pos = vim.fn.getpos("'>")
                    local start_row = start_pos[2] - 1
                    local start_col = start_pos[3] - 1
                    local end_row = end_pos[2] - 1
                    local last_line = vim.api.nvim_buf_get_lines(0, end_row, end_row + 1, false)[1] or ""
                    local end_col = math.min(end_pos[3], #last_line)
                    local ok, lines = pcall(vim.api.nvim_buf_get_text, 0, start_row, start_col, end_row, end_col, {})
                    if not ok or #lines == 0 then
                        vim.notify("99: could not get selection", vim.log.levels.WARN)
                        return
                    end
                    local text = table.concat(lines, "\n")
                    local prompt = string.format(
                        "Explain this code from %s:\n\n```%s\n%s\n```",
                        file, ft, text
                    )
                    _99.search({ additional_prompt = prompt })
                end, { desc = "99: explain selection" })
                vim.keymap.set("n", "<leader>9b", function()
                    local file = vim.fn.expand("%:.")
                    if file == "" then
                        vim.notify("99: no file in current buffer", vim.log.levels.WARN)
                        return
                    end
                    vim.ui.input({
                        prompt = "Ask about @" .. file .. ": ",
                        default = "@" .. file .. " ",
                    }, function(input)
                        if input and input ~= "" then
                            _99.search({ additional_prompt = input })
                        end
                    end)
                end, { desc = "99: search with current buffer" })
                vim.keymap.set("n", "<leader>9m", function()
                    local provider = _99.get_provider()
                    provider.fetch_models(function(models, err)
                        if err or not models then
                            vim.notify("99: " .. (err or "unknown error"), vim.log.levels.ERROR)
                            return
                        end
                        vim.ui.select(models, {
                            prompt = "99 model (current: " .. _99.get_model() .. "): ",
                        }, function(choice)
                            if choice then
                                _99.set_model(choice)
                                vim.notify("99: model → " .. choice)
                            end
                        end)
                    end)
                end, { desc = "99: switch model" })
            end,
        },
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
            "MeanderingProgrammer/render-markdown.nvim",
            dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
            ft = { "markdown", "md" },
            opts = {},
        },
        {
            "ThePrimeagen/harpoon",
            branch = "harpoon2",
            dependencies = { "nvim-lua/plenary.nvim" },
            config = function()
                local harpoon = require("harpoon")
                harpoon:setup()

                vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
                vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

                vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
                vim.keymap.set("n", "<C-j>", function() harpoon:list():select(2) end)
                vim.keymap.set("n", "<C-k>", function() harpoon:list():select(3) end)
                vim.keymap.set("n", "<C-l>", function() harpoon:list():select(4) end)
            end,
        },
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
                require("mini.pick").setup({
                    mappings = {
                        move_down = '<C-j>',
                        move_up   = '<C-k>',
                    },
                })
                require("mini.icons").setup({})
            end
        },
        {
            "folke/tokyonight.nvim",
            lazy = false,
            priority = 1000,
            opts = {
                style = "night", -- This is the darkest variant
                transparent = false, -- Ensure transparency is off
                on_colors = function(colors)
                    colors.bg = "#000000" -- Force background to solid black
                end
            },
            config = function(_, opts)
                require("tokyonight").setup(opts)
                vim.cmd([[colorscheme tokyonight-night]])
            end,
    },
        {
            "lewis6991/gitsigns.nvim",
            config = function()
                require("gitsigns").setup({
                    signs = {
                        add          = { text = "▎" },
                        change       = { text = "▎" },
                        delete       = { text = "" },
                        topdelete    = { text = "" },
                        changedelete = { text = "▎" },
                    },
                    signcolumn = true,
                    current_line_blame = true,
                    current_line_blame_opts = {
                        delay = 500,
                        virt_text_pos = "eol",
                    },
                })
                vim.keymap.set("n", "<leader>gb", ":Gitsigns toggle_current_line_blame<CR>", { desc = "Toggle git blame" })
                vim.keymap.set("n", "<leader>gp", ":Gitsigns preview_hunk<CR>",              { desc = "Preview hunk" })
                vim.keymap.set("n", "<leader>gs", ":Gitsigns stage_hunk<CR>",                { desc = "Stage hunk" })
                vim.keymap.set("n", "<leader>gu", ":Gitsigns undo_stage_hunk<CR>",           { desc = "Unstage hunk" })
                vim.keymap.set("n", "<leader>gx", ":Gitsigns reset_hunk<CR>",                { desc = "Reset hunk" })
                vim.keymap.set("n", "]h",          ":Gitsigns next_hunk<CR>",                { desc = "Next hunk" })
                vim.keymap.set("n", "[h",          ":Gitsigns prev_hunk<CR>",                { desc = "Prev hunk" })
            end,
        },
        {
            "NeogitOrg/neogit",
            dependencies = {
                "nvim-lua/plenary.nvim",
                "sindrets/diffview.nvim",
            },
            config = function()
                require("neogit").setup({ kind = "tab" })
                vim.keymap.set("n", "<leader>gg", ":Neogit<CR>", { desc = "Neogit" })
                vim.keymap.set("n", "<leader>gm", function()
                    local items = vim.fn.systemlist("git submodule foreach --quiet 'echo $displaypath'")
                    if #items == 0 then
                        vim.notify("No submodules found", vim.log.levels.WARN)
                        return
                    end
                    require("mini.pick").start({
                        source = {
                            items = items,
                            name  = "Git Submodules",
                            choose = function(item)
                                vim.schedule(function()
                                    vim.cmd("Neogit cwd=" .. item)
                                end)
                            end,
                        },
                    })
                end, { desc = "Neogit submodule picker" })
            end,
        },
        {
            "akinsho/toggleterm.nvim",
            version = "*",
            config = function()
                require("toggleterm").setup({
                    size = 20,
                    open_mapping = [[<C-\>]],
                    direction = "float",
                    float_opts = { border = "curved" },
                })
                vim.keymap.set("n", "<leader>tf", ":ToggleTerm direction=float<CR>",      { desc = "Terminal float" })
                vim.keymap.set("n", "<leader>t-",  ":ToggleTerm direction=horizontal<CR>", { desc = "Terminal horizontal" })
                vim.keymap.set("n", [[<leader>t\]], ":ToggleTerm direction=vertical<CR>", { desc = "Terminal vertical" })
                vim.keymap.set("t", "<Esc>",       [[<C-\><C-n>]],                        { desc = "Exit terminal mode" })
                vim.keymap.set("n", "<leader>th", ":1ToggleTerm<CR>", { desc = "Terminal 1" })
                vim.keymap.set("n", "<leader>tj", ":2ToggleTerm<CR>", { desc = "Terminal 2" })
                vim.keymap.set("n", "<leader>tk", ":3ToggleTerm<CR>", { desc = "Terminal 3" })
                vim.keymap.set("n", "<leader>tl", ":4ToggleTerm<CR>", { desc = "Terminal 4" })
            end,
        },
        {
            "mbbill/undotree",
            config = function()
                vim.keymap.set("n", "<leader>u", ":UndotreeToggle<CR>", { desc = "Toggle undotree" })
            end,
        },
        -- {
        --     "zbirenbaum/copilot.lua",
        --     event = "VeryLazy",
        --     enabled= vim.fn.executable("node") == 1,
        --     config = function ()
        --         require("copilot").setup({
        --             suggestion = {
        --                 enabled = true,
        --                 auto_trigger = true,
        --                 trigger_on_accept = false,
        --                 keymaps = {
        --                   accept = false,
        --                   accept_word = false,
        --                   accept_line = false,
        --                   next = false,
        --                   prev = false,
        --                   dismiss = false,
        --                 }
        --             },
        --             panel = {
        --                 enabled = false
        --             },
        --             filetypes = {
        --                 ["*"] = true
        --             }
        --         })
        --
        --         vim.b.copilot_suggestion_hidden = false
        --
        --     end,
        -- },
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
                -- "zbirenbaum/copilot-cmp",
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
                -- local copilot_cmp  = require("copilot_cmp")

                -- copilot_cmp.setup()
                mason.setup()

                -- 2) Prepare capabilities for nvim-cmp
                local capabilities = cmp_nvim_lsp.default_capabilities()

                -- 3) Tell mason-lspconfig which servers to ensure & how to set them up
                mlsp.setup({
                    ensure_installed = {
                        "clangd",  -- C, C++, CUDA
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
