local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true

vim.diagnostic.config({ virtual_text = false })

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    local bufnr = args.buf

    vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'

    local function map(mode, lhs, rhs)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, noremap = true, silent = true })
    end

    map('n', '<space>c', vim.lsp.buf.declaration)
    map('n', '<space>d', vim.lsp.buf.definition)
    map('n', '<space>a', vim.lsp.buf.code_action)
    map('n', '<space>h', vim.lsp.buf.hover)
    map('n', '<space>s', vim.lsp.buf.signature_help)
    map('n', '<space>t', vim.lsp.buf.type_definition)
    map('n', '<space>n', vim.lsp.buf.rename)
    map('n', '<space>e', vim.diagnostic.open_float)
    map('n', '[d', vim.diagnostic.goto_prev)
    map('n', ']d', vim.diagnostic.goto_next)

    if client and client.server_capabilities.documentFormattingProvider then
      map('n', 'ff', function() vim.lsp.buf.format() end)
    end

    if client and client.server_capabilities.documentHighlightProvider then
      vim.cmd [[
        hi LspReferenceRead cterm=bold ctermbg=DarkMagenta guibg=LightYellow
        hi LspReferenceText cterm=bold ctermbg=DarkMagenta guibg=LightYellow
        hi LspReferenceWrite cterm=bold ctermbg=DarkMagenta guibg=LightYellow

        function! ToggleAutoHighlight()
          if !exists('#lsp_document_highlight#CursorHold')
            augroup lsp_document_highlight
              autocmd! * <buffer>
              autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()
              autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()
            augroup END
          else
              augroup lsp_document_highlight
                  autocmd!
                  lua vim.lsp.buf.clear_references()
              augroup END
          endif
        endfunction

        nnoremap <F4> :call ToggleAutoHighlight()<CR>
      ]]
    end
  end,
})

vim.lsp.config('pyright', {
  capabilities = capabilities,
})

vim.lsp.config('gopls', {
  cmd = {'gopls'},
  capabilities = capabilities,
  settings = {
    gopls = {
      experimentalPostfixCompletions = true,
      analyses = {
        unusedparams = true,
        unusedwrite = true,
        fillstruct = false,
      },
      staticcheck = true,
      gofumpt = true,
    },
  },
})

vim.lsp.config('rust_analyzer', {
  capabilities = capabilities,
})

vim.lsp.config('bashls', {
  capabilities = capabilities,
})

vim.lsp.config('ruby_lsp', {
  capabilities = capabilities,
  init_options = {
    formatter = 'standard',
    linters = { 'standard' },
  },
})

vim.lsp.enable({'pyright', 'gopls', 'rust_analyzer', 'bashls', 'ruby_lsp'})

require("typescript-tools").setup {
  settings = {
    separate_diagnostic_server = true,
    publish_diagnostic_on = "insert_leave",
    expose_as_code_action = {},
    tsserver_path = nil,
    tsserver_plugins = {},
    tsserver_max_memory = "auto",
    tsserver_format_options = {},
    tsserver_file_preferences = {},
    tsserver_locale = "en",
    complete_function_calls = false,
    include_completions_with_insert_text = true,
    code_lens = "off",
    disable_member_code_lens = true,
    jsx_close_tag = {
        enable = false,
        filetypes = { "javascriptreact", "typescriptreact" },
    }
  },
}

-- Treesitter: enable highlighting for all filetypes with installed parsers
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

local ts_ok, ts = pcall(require, 'nvim-treesitter')
if ts_ok then
  ts.install({
    "bash", "css", "go", "gomod", "gosum", "html", "javascript",
    "json", "lua", "markdown", "python", "ruby", "rust", "toml",
    "typescript", "tsx", "vim", "vimdoc", "yaml",
  })
end

require("dapui").setup({
  icons = { expanded = "▾", collapsed = "▸" },
  mappings = {
    expand = { "<CR>", "<2-LeftMouse>" },
    open = "o",
    remove = "d",
    edit = "e",
    repl = "r",
  },
  sidebar = {
    elements = {
      {
        id = "scopes",
        size = 0.50,
      },
      { id = "breakpoints", size = 0.25 },
      { id = "stacks", size = 0.25 },
    },
    size = 80,
    position = "right",
  },
  tray = {
    elements = { "repl" },
    size = 10,
    position = "bottom",
  },
  floating = {
    max_height = nil,
    max_width = nil,
    border = "single",
    mappings = {
      close = { "q", "<Esc>" },
    },
  },
  windows = { indent = 1 },
})

local ok, ls = pcall(require, "luasnip")
if ok then
  vim.keymap.set({"i", "s"}, "<C-j>", function()
    if ls.expand_or_jumpable() then
      ls.expand_or_jump()
    end
  end, { silent = true })

  vim.keymap.set({"i", "s"}, "<C-k>", function()
    if ls.jumpable(-1) then
      ls.jump(-1)
    end
  end, { silent = true })

  require("luasnip.loaders.from_snipmate").lazy_load()
end

function goimports(timeout_ms)
    local params = vim.lsp.util.make_range_params()
    params.context = { only = { "source.organizeImports" } }

    local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
    if not result or next(result) == nil then return end

    for _, res in pairs(result) do
      if res.result then
        for _, action in ipairs(res.result) do
          if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit, "utf-8")
          end
        end
      end
    end
end
