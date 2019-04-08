
fun! s:on_save()
    let max = has('nvim') ? get(g:, 'GuiWindowMaximized') : (has('gui_running') && getwinposx()<0 && getwinposy()<0)
    let data = {'max': max}
    if &title && len(&titlestring)
        let data.title = &titlestring
    endif
    call proj#config('gui.json', data)
    call s:close_spec_windows()
endf

fun! s:on_load(...)
    if !exists('g:Proj') | return | endif
    let data = proj#config('gui.json')
    let max = !empty(data) && get(data, 'max')

    if has('nvim')
        if max && exists('*GuiWindowMaximized')
            call GuiWindowMaximized(1)
        endif
    elseif has('gui_running') && max
        simalt ~x
    endif

    if has_key(data, 'title')
        set title
        let &titlestring = data['title']
        let g:titlestring = data['title']
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

au User BeforeProjSave  call <sid>on_save()
au User AfterProjLoaded call <sid>on_load()
