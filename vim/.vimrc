" CONFIGURAÇÃO BASE DO VIMRC
" ============================================

" --- GERAL ---
set nocompatible              " Desativa compatibilidade com Vi antigo
set encoding=utf-8            " Encoding padrão
set history=500               " Histórico de comandos
set autoread                  " Recarrega arquivo se alterado externamente
set hidden                    " Permite trocar buffer sem salvar

" --- INTERFACE ---
set number                    " Números de linha
set relativenumber            " Números relativos (ótimo para navegação)
set cursorline                " Destaca a linha atual
set showcmd                   " Mostra comando parcial no rodapé
set noshowmode                " A lightline já mostra o modo; evita duplicar
set wildmenu                  " Menu de autocompletar na linha de comando
set laststatus=2              " Sempre mostrar a barra de status
set scrolloff=8               " Mantém 8 linhas de contexto ao rolar
set sidescrolloff=8           " Mesmo para scroll horizontal
set signcolumn=yes            " Coluna de sinais (erros, git, etc)

" --- BUSCA ---
set incsearch                 " Busca incremental (enquanto digita)
set hlsearch                  " Destaca resultados da busca
set ignorecase                " Ignora maiúsculas/minúsculas na busca
set smartcase                 " ...mas respeita se você usar maiúsculas

" --- INDENTAÇÃO ---
set tabstop=4                 " Tab = 4 espaços (visual)
set softtabstop=4             " Tab = 4 espaços (edição)
set shiftwidth=4              " Indentação com >> e
set expandtab                 " Converte tab em espaços
set smartindent               " Indentação inteligente
set autoindent                " Mantém indentação da linha anterior

" --- APARÊNCIA ---
syntax on                     " Habilita syntax highlighting
set background=dark           " Fundo escuro

" Truecolor. Dentro do tmux o vim não detecta os escapes sozinho
" (t_8f/t_8b vêm vazios), então precisam ser declarados na mão.
if has('termguicolors')
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
    set termguicolors
endif

" --- PERFORMANCE ---
set lazyredraw                " Não redesenha durante macros
set ttyfast                   " Transmissão mais rápida no terminal
set updatetime=100            " Sinais do gitgutter em 100ms (default: 4000)

" --- ARQUIVOS E BACKUP ---
set noswapfile                " Sem arquivos .swp
set nobackup                  " Sem arquivos de backup
set undofile                  " Histórico de undo persistente entre sessões
set undodir=~/.vim/undodir    " Diretório para undo persistente

" --- SPLITS ---
set splitbelow                " Novo split abre abaixo
set splitright                " Novo split abre à direita

" --- CLIPBOARD ---
" Exige um vim com +clipboard (no Arch: pacote gvim, não vim). No WSL2 o
" WSLg faz a ponte entre a seleção do X11 e o clipboard do Windows.
set clipboard=unnamedplus     " Integra com clipboard do sistema
if !has('clipboard')
    autocmd VimEnter * echohl WarningMsg
        \ | echom 'vim sem +clipboard: unnamedplus e <leader>y não funcionam (instale gvim)'
        \ | echohl None
endif

" ============================================
"  KEYMAPS
" ============================================

let mapleader = " "           " Leader key = Espaço

" Limpar destaque da busca
nnoremap <leader>h :nohlsearch<CR>

" Salvar e sair rápido
nnoremap <leader>w :w<CR>
nnoremap <leader>q :q<CR>

" Navegar entre splits com Ctrl+hjkl.
" O vim-tmux-navigator sobrescreve estes mapas no plug#end() e estende a
" navegação para além das bordas do vim, entrando nos panes do tmux.
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Navegar entre buffers
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Mover linhas selecionadas (modo visual)
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Manter cursor centralizado ao rolar
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" Manter cursor centralizado ao buscar
nnoremap n nzzzv
nnoremap N Nzzzv

" Colar sem perder o que está no clipboard
xnoremap <leader>p "_dP

" Copiar para clipboard do sistema
nnoremap <leader>y "+y
vnoremap <leader>y "+y

" ============================================
"  PLUGINS (vim-plug)
" ============================================

" Instale o vim-plug primeiro:
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
"   https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

call plug#begin('~/.vim/plugged')


Plug 'prabirshrestha/vim-lsp'
Plug 'mattn/vim-lsp-settings'
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'prabirshrestha/asyncomplete-lsp.vim'

Plug 'uiiaoo/java-syntax.vim'

Plug 'tpope/vim-fugitive'           " Git integrado
Plug 'tpope/vim-surround'           " Manipular aspas, parênteses, tags
Plug 'tpope/vim-commentary'         " Comentar com gc
Plug 'airblade/vim-gitgutter'       " Indicadores de git na coluna
Plug 'christoomey/vim-tmux-navigator' " C-h/j/k/l entre panes do vim e do tmux
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'             " Fuzzy finder

Plug 'itchyny/lightline.vim'        " Barra de status leve
Plug 'github/copilot.vim'           " GitHub Copilot
Plug 'dracula/vim', {'as': 'dracula'}

call plug#end()

"colorscheme dracula

" ============================================
"  CONFIG DOS PLUGINS
" ============================================

" fzf — buscar arquivos e texto
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :Rg<CR>
nnoremap <leader>fb :Buffers<CR>

" lightline — tema neutro, não depende de nenhum colorscheme instalado
let g:lightline = { 'colorscheme': 'wombat' }

" vim-lsp — mapas locais ao buffer, ativados só quando há servidor conectado
func! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    if exists('+tagfunc')
        setlocal tagfunc=lsp#tagfunc
    endif
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> gi <plug>(lsp-implementation)
    nmap <buffer> gt <plug>(lsp-type-definition)
    nmap <buffer> K  <plug>(lsp-hover)
    nmap <buffer> [g <plug>(lsp-previous-diagnostic)
    nmap <buffer> ]g <plug>(lsp-next-diagnostic)
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    nmap <buffer> <leader>ca <plug>(lsp-code-action)
    nmap <buffer> <leader>fm <plug>(lsp-document-format)
endfunc

augroup lsp_install
    autocmd!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

let g:lsp_diagnostics_echo_cursor = 1
let g:lsp_diagnostics_virtual_text_enabled = 0

" Criar diretório de undo se não existir
if !isdirectory($HOME . '/.vim/undodir')
    call mkdir($HOME . '/.vim/undodir', 'p')
endif
