set nocompatible
let neo = has("nvim")
if !neo
	call plug#begin('~/.vim/plugged')
	Plug 'joshdick/onedark.vim'
	call plug#end()
endif
set relativenumber number
set autoindent
set smartindent
set backspace=2
set tabstop=4
set shiftwidth=4
set nowrap 
set ruler 
set noswapfile
set hlsearch
set clipboard=unnamedplus
set laststatus=2
set guicursor=a:ver25
set termguicolors
set cursorline
set scrolloff=3
augroup filetypeindent 
  autocmd!
  autocmd FileType json,svg,scss,less,css,lua,vim,javascript,xml,sh,zsh,typescript,html,typescriptreact,javascriptreact set ai sw=2 ts=2 sts=2
augroup END

autocmd BufRead,BufNewFile ~/.oh-my-zsh/custom/functions/* if expand('<afile>:e') == '' | setfiletype zsh | endif
autocmd BufReadPre */node_modules/* setlocal readonly

" Copy file/dir paths to the system clipboard
command! CopyRelativeFilePath let @+ = fnamemodify(expand('%'), ':.') | echo @+
command! CopyRelativeParentPath let @+ = fnamemodify(expand('%'), ':.:h') | echo @+
command! CopyAbsoluteFilePath let @+ = expand('%:p') | echo @+
command! CopyAbsoluteParentPath let @+ = expand('%:p:h') | echo @+
command! CopyWorkspacePath let @+ = getcwd() | echo @+

syntax on
if !neo
	colorscheme onedark
endif
