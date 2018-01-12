" =============================================================================
" Filename:     autoload/proj/nerdtree.vim
" Author:       luzhlon
" Function:     Save/Load gui windows state and NERDTree
" Last Change:  2017-10-03
" =============================================================================

fun! s:OnSave()
    let w = s:NERDClose()
    call proj#config('viewext.json', {'NERD': w})
endf

fun! s:OnLoad()
    let exts = proj#config('viewext.json')
    if !empty(exts) && exts.NERD
        exe empty(&bt) && !empty(@%) ? 'NERDTreeFind': 'NERDTree'
        exe 'vert' 'resize' exts.NERD
        normal zz
        winc p
    endif
endf

au User BeforeProjSave  call <SID>OnSave()
au User AfterProjLoaded call <SID>OnLoad()

" Close the NERDTree, return it's window width if exists
fun! s:NERDClose()
    let i = 0
    let cur_wid = win_getid()
    while 1                 " Enum the window's buffer
        let b = winbufnr(i)
        if b < 0 | break | endif
        " A NerdTree window exists
        if getbufvar(b, '&bt') == 'nofile' && getbufvar(b, '&ft') == 'nerdtree'
            let id = win_getid(i)
            call win_gotoid(id)
            if &bt != 'nofile' | continue | endif
            let wi = getwininfo(id)
            " Close the NerdTree window
            set bh=wipe
            winc c
            call win_gotoid(cur_wid) " Go back to original window
            " Return the width of NerdTree window
            return wi[0].width
        endif
        let i += 1
    endw
    return 0
endf
