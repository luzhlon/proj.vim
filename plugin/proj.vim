" =============================================================================
" Filename:     plugin/work.vim
" Author:       luzhlon
" Function:     workspace
" Last Change:  2017/4/08
" =============================================================================

let g:proj#dirname = get(g:, 'proj#dirname', '.vimproj')

com! ProjCreate call proj#create()
com! ProjDelete call proj#delete()
com! ProjSelect Denite proj
com! ProjConfig exe 'edit' g:Proj['confdir'].'/config.vim'
com! -nargs=+ -complete=dir ProjCD call proj#try_cd(<q-args>)

if argc() | finish | endif

if isdirectory(proj#confdir(getcwd()))
    call proj#_init()
endif
