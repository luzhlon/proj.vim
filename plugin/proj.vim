" =============================================================================
" Filename:     plugin/work.vim
" Author:       luzhlon
" Function:     workspace
" Last Change:  2017/4/08
" =============================================================================

com! ProjCreate call proj#create()
com! ProjDelete call proj#delete()

if argc() | finish | endif

let s:confdir = getcwd() . '/.vimproj'
if isdirectory(s:confdir)
    call proj#_init(s:confdir)
endif
