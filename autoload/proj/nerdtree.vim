" =============================================================================
" Filename:     autoload/proj/nerdtree.vim
" Author:       luzhlon
" Function:     Save/Load gui windows state and NERDTree
" Last Change:  2017-10-03
" =============================================================================

fun! s:OnSave()
    let w = s:NERDClose()
    call proj#config('nerdtree.json', {'width': w})
endf

fun! s:OnLoad()
    let exts = proj#config('nerdtree.json')
    if !empty(exts) && exts.width
        exe empty(&bt) && !empty(@%) ? 'NERDTreeFind': 'NERDTree'
        exe 'vertical' 'resize' exts['width']
        norm! zz
        winc p
    endif
endf

au User BeforeProjSave nested  call <SID>OnSave()
au User AfterProjLoaded nested call <SID>OnLoad()

" Close the NERDTree, return it's window width if exists
fun! s:NERDClose()
    let i = 0
    let cur_wid = win_getid()
    while 1                 " Enum the window's buffer
        let nr = winbufnr(i)
        if nr < 0 | return 0 | endif
        " A NerdTree window exists
        if getbufvar(nr, '&bt') == 'nofile' && getbufvar(nr, '&ft') == 'nerdtree'
            let id = win_getid(i)
            call win_gotoid(id)
            " if &bt != 'nofile' | continue | endif
            let width = winwidth('.')
            " Close the NerdTree window
            noautocmd bw!
            silent! close
            " Goto original window
            if cur_wid != win_getid()
                call win_gotoid(cur_wid)
            endif
            return width
        endif
        let i += 1
    endw
endf
