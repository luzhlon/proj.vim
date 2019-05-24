
fun! s:on_save()
    let width = 0
    if win_gotoid(win_getid(1)) && &ft == 'defx'
        let width = winwidth(0)
    endif
    call proj#config('defx', {'width': width})
endf

fun! s:on_load()
    let conf = proj#config('defx')
    if !empty(conf) && get(conf, 'width')
        exec 'Defx -search=`expand(''%:p'')` -split=topleft -split=vertical -winwidth=' . conf['width']
        call timer_start(10, {t->&ft=='defx' ? [execute('winc p'), timer_stop(t)] :0}, {'repeat': 50})
    endif
endf

au User BeforeProjSave ++nested call <sid>on_save()
au User AfterProjLoaded ++nested call <sid>on_load()
