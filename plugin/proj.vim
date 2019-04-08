" =============================================================================
" Filename:     plugin/work.vim
" Author:       luzhlon
" Function:     workspace
" Last Change:  2017/4/08
" =============================================================================

com! ProjCreate call proj#create()
com! ProjDelete call proj#delete()
" com! ProjSelect call proj#select_history()
com! ProjSelect Denite proj

com! ProjConfig exe 'edit' g:Proj['confdir'].'/config.vim'

if argc() | finish | endif

let s:confdir = getcwd() . '/.vimproj'
if isdirectory(s:confdir)
    call proj#_init()
endif

fun! s:proj_cd(dir)
    if has_key(g:, 'Proj') | return | endif
    let confdir = a:dir . '/.vimproj'
    if isdirectory(confdir)
        call proj#cd(a:dir)
    else
        echo confdir 'Not Exists'
    endif
endf

com! -nargs=+ -complete=dir ProjCD call <sid>proj_cd(<q-args>)
