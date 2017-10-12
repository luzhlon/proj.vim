" =============================================================================
" Filename:     plugin/work.vim
" Author:       luzhlon
" Function:     workspace
" Last Change:  2017/4/08
" =============================================================================

fun! s:main()
    let arg = argv(0)
    if fnamemodify(arg, ':t') == '.vimpro.json' && filereadable(arg)
        call proj#_init(arg)

        argglobal
        silent! argdel *
        silent! exe 'bw' arg
        " non-block the nvim process for nvim-qt can attach it
        au VimEnter    * sil! call proj#load()
        au VimLeavePre * call proj#save()
        au BufWinEnter * call proj#loadview()
        au BufWinLeave * call proj#saveview()
        runtime! autoload/proj/*.vim
    endif
endf

call s:main()

com! ProjCreate call proj#create()
com! ProjDelete call proj#delete()
