
fun! s:OnSave()
    let max = has('nvim') ? get(g:, 'GuiWindowMaximized') : (has('gui_running') && getwinposx()<0 && getwinposy()<0)
    call proj#config('gui.json', {'max': max})
    call s:close_spec_windows()
endf

fun! s:OnLoad()
    if !exists('g:Proj') | return | endif
    let gui = proj#config('gui.json')
    let max = !empty(gui) && get(gui, 'max')

    if has('nvim')
        if max && exists('*GuiWindowMaximized')
            call GuiWindowMaximized(1)
        endif
    elseif has('gui_running') && max
        simalt ~x
    endif

    if &title
        set title
        let &titlestring = &titlestring
    endif
endf

fun! s:close_spec_windows()
    let cur_wid = win_getid()
    for i in range(1, winnr('$'))
        " A NerdTree window exists
        let bt = getbufvar(winbufnr(i), '&bt')
        if bt == 'nofile' || bt == 'quickfix'
            call win_gotoid(win_getid(i))
            " Close the 'nofile' window
            try | close |
            catch
                noautocmd bw!
            endtry
        endif
    endfor
    " Goto original window
    if cur_wid != win_getid()
        call win_gotoid(cur_wid)
    endif
endf

au User BeforeProjSave  call <SID>OnSave()
au VimEnter * call <SID>OnLoad()
