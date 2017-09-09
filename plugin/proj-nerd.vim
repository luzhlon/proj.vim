" =============================================================================
" Filename:     plugin/work/viewext.vim
" Author:       luzhlon
" Function:     Save/Load gui windows state and NERDTree
" Last Change:  2017/4/08
" =============================================================================
fun! s:OnSave()
    let w = s:NERDClose()
    let exts = {
        \ 'MAX': has('gui_running')?(getwinposx()<0&&getwinposy()<0):0,
        \ 'NERD': w
    \ }
    call proj#config('viewext.json', exts)
endf

fun! s:OnLoad()
    let exts = proj#config('viewext.json')
    " Maximize the window
    if exts.MAX && has('gui_running')
        simalt ~x
    endif
    if exts.NERD
        NERDTree
        exe 'vertical' 'resize' exts.NERD
        winc p
    endif
endf

au User BeforeProjSave  call <SID>OnSave()
au User AfterProjLoaded call <SID>OnLoad()

" Close the NERDTree, return it's window width if exists
fun! s:NERDClose()
    let i = 0
    while 1
        let b = winbufnr(i)
        if b < 0 | break | endif
        if getbufvar(b, '&bt') == 'nofile' && getbufvar(b, '&ft') == 'nerdtree'
            let id = win_getid(i)
            call win_gotoid(id)
            if &bt != 'nofile' | continue | endif
            let wi = getwininfo(id)
            winc c | winc p
            exe b 'bw'
            return wi[0].width
        endif
        let i += 1
    endw
    return 0
endf
