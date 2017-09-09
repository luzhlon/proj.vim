
fun! s:OnLoad()
    if &title
        set title
        let &titlestring = &titlestring
    endif
endf

au GUIEnter * call <SID>OnLoad()
