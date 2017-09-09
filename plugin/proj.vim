" =============================================================================
" Filename:     plugin/work.vim
" Author:       luzhlon
" Function:     workspace
" Last Change:  2017/4/08
" =============================================================================

fun! s:main()
    let arg = argv(0)
    if fnamemodify(arg, ':t') == '.vimpro.json' && filereadable(arg)
        " Check default settings
        let g:Proj = {}
        " Project's config file
        let g:Proj.file = arg
        " Project's directory
        let g:Proj.dir = fnamemodify(arg, ':p:h')

        exe 'au' 'VimEnter' '*' 'bd' arg
        au VimEnter    * call proj#load()
        au VimLeavePre * call proj#save()
    endif
endf

call s:main()

com! ProjCreate call proj#create()
com! ProjDelete call proj#delete()
