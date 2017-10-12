
fun! s:OnSave()
    let max = 0
    if has('nvim')
        if exists('g:GuiWindowMaximized') && g:GuiWindowMaximized
            let max = 1
        endif
    elseif has('gui_running')
        let max = getwinposx()<0 && getwinposy()<0
    endif
    call proj#config('gui.json', {'max': max})
endf

fun! s:OnLoad()
    if !exists('g:Proj') | return | endif
    let gui = proj#config('gui.json')

    if has('nvim')
        if gui.max && exists('*GuiWindowMaximized')
            call GuiWindowMaximized(1)
        endif
    elseif has('gui_running') && gui.max
        simalt ~x
    endif

    if &title
        set title
        let &titlestring = &titlestring
    endif
endf

au User BeforeProjSave  call <SID>OnSave()
au GUIEnter * call <SID>OnLoad()
