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
  autocmd FileType
		\ json,
		\svg,
		\scss,
		\less,
		\css,
		\lua,
		\vim,
		\javascript,
		\xml,
		\sh,
		\zsh,
		\typescript,
		\html,
		\typescriptreact,
		\javascriptreact
		\ setlocal ai sw=2 ts=2 sts=2
augroup END

autocmd BufRead,BufNewFile ~/.oh-my-zsh/custom/functions/* if expand('<afile>:e') == '' | setfiletype zsh | endif
" Make third-party & standard library files read-only
augroup libreadonly
  autocmd!
  " JS/TS: node_modules (3rd party)
  autocmd BufReadPre */node_modules/* setlocal readonly nomodifiable
  " Python: site-packages / dist-packages (3rd party) + stdlib
  autocmd BufReadPre */site-packages/* setlocal readonly nomodifiable
  autocmd BufReadPre */dist-packages/* setlocal readonly nomodifiable
  autocmd BufReadPre */lib/python[0-9]*/* setlocal readonly nomodifiable
  " Go: module cache (3rd party) + GOROOT stdlib
  autocmd BufReadPre */go/pkg/mod/* setlocal readonly nomodifiable
  autocmd BufReadPre */go/src/* setlocal readonly nomodifiable
  autocmd BufReadPre */libexec/src/*.go setlocal readonly nomodifiable
  " Lua: luarocks (3rd party) + system lua
  autocmd BufReadPre */lua_modules/* setlocal readonly nomodifiable
  autocmd BufReadPre */.luarocks/* setlocal readonly nomodifiable
  autocmd BufReadPre */share/lua/* setlocal readonly nomodifiable
  " Rust: cargo registry (3rd party) + rustup toolchain std source
  autocmd BufReadPre */.cargo/registry/* setlocal readonly nomodifiable
  autocmd BufReadPre */.rustup/toolchains/* setlocal readonly nomodifiable
  " Neovim: bundled runtime (built-in) + installed plugins (3rd party)
  autocmd BufReadPre */share/nvim/runtime/* setlocal readonly nomodifiable
  autocmd BufReadPre */nvim/site/pack/*/start/* setlocal readonly nomodifiable
  autocmd BufReadPre */nvim/site/pack/*/opt/* setlocal readonly nomodifiable
  autocmd BufReadPre */nvim/lazy/* setlocal readonly nomodifiable
  autocmd BufReadPre */nvim/plugged/* setlocal readonly nomodifiable
  " lua-language-server: bundled meta defs + generated meta cache (built-in defs)
  autocmd BufReadPre */lua-language-server/*/libexec/meta/* setlocal readonly nomodifiable
  autocmd BufReadPre */.cache/lua-language-server/meta/* setlocal readonly nomodifiable
  autocmd BufReadPre */lua-language-server/meta/* setlocal readonly nomodifiable
augroup END

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
