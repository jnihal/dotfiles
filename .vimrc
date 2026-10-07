syntax on
set relativenumber
set autoindent
filetype plugin indent on
set clipboard=unnamedplus

set textwidth=80
autocmd FileType gitcommit set textwidth=72 cc=73
autocmd FileType gitcommit setlocal spell

nnoremap <C-w> {gq}
nnoremap <C-e> viwb<ESC><ESC>i`<ESC>ea`<ESC>
nnoremap <C-b> viwb<ESC><ESC>i**<ESC>ea**<ESC>

