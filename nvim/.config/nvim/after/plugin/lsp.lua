-- LSP  
local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local on_attach = function(client, bufnr)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer=0 })
    vim.keymap.set('n', '<S-b>', vim.lsp.buf.definition, { buffer=0 })
    vim.keymap.set('n', '<Leader>D', vim.lsp.buf.type_definition, { buffer=0 })
    vim.keymap.set('n', '<Leader>gi', vim.lsp.buf.implementation, { buffer=0 })
    vim.keymap.set('n', '<Leader>ca', vim.lsp.buf.code_action, { buffer=0 })
    vim.keymap.set('n', 'gr', "<cmd>Telescope lsp_references<cr>", { buffer=0 })
    vim.keymap.set('n', '<Leader>r', function() 
        vim.lsp.buf.rename()
        vim.cmd([[wa]])
    end)
end
require('lspconfig')['tsserver'].setup {on_attach = on_attach, capabilities = capabilities}
vim.opt.completeopt = {'menu', 'menuone', 'noselect'}
  -- Set up nvim-cmp.
  local cmp = require'cmp'

  cmp.setup({
    snippet = {
      expand = function(args)
        -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
           require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
        -- require('snippy').expand_snippet(args.body) -- For `snippy` users.
        -- vim.fn["UltiSnips#Anon"](args.body) -- For `ultisnips` users.
      end,
    },
    window = {
      -- completion = cmp.config.window.bordered(),
      -- documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
      ['<C-b>'] = cmp.mapping.scroll_docs(-4),
      ['<C-f>'] = cmp.mapping.scroll_docs(4),
      ['<C-Space>'] = cmp.mapping.complete(),
      ['<C-e>'] = cmp.mapping.abort(),
      ['<CR>'] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item. Set `select` to `false` to only confirm explicitly selected items.
    }),
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'luasnip' }, -- For luasnip users.
      -- { name = 'ultisnips' }, -- For ultisnips users.
      -- { name = 'snippy' }, -- For snippy users.
    }, {
      { name = 'buffer' },
    })
  })

  -- Use cmdline & path source for ':' (if you enabled `native_menu`, this won't work anymore).
  cmp.setup.cmdline(':', {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = 'path' }
    }, {
      { name = 'cmdline' }
    })
  })
