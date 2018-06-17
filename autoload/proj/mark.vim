
fun! s:toggle_mark()
    let marks = proj#config('marks.json')
    if type(marks) != v:t_dict
        call proj#config('marks.json', {})
        return s:toggle_mark()
    endif

    let name = input('Mark name: ')
    if len(name)
        let name = substitute(name, '\s', '_', 'g')
        let marks[name] = [expand('%:.'), line('.')]
        call proj#config('marks.json', marks)
    endif
endf

fun! s:marks_win()
    badd _ProjMarks
    let wid = bufwinid('_ProjMarks')
    if wid < 0
        b _ProjMarks
    else
        call win_gotoid(wid)
    endif

    %delete
    setl bt=nowrite bh=wipe ul=-1 nowrap

    nnoremap <buffer><silent><cr> :call <sid>on_enter()<cr>
    nnoremap <buffer><silent><esc> :call vim#closefile()<cr>
    nnoremap <buffer><silent>d :call <sid>on_delete()<cr>
    nnoremap <buffer><silent>r :call <sid>on_rename()<cr>
endf

fun! s:on_enter()
    let name = matchstr(getline('.'), '\S\+')
    let marks = proj#config('marks.json')
    let [file, line] = marks[name]
    exe 'badd' file
    exe 'b! +' . line file
endf

fun! s:on_delete()
    if confirm('Delete this mark?', "&Yes\n&No") == 1
        let marks = proj#config('marks.json')
        let name = matchstr(getline('.'), '\S\+')
        unlet marks[name]
        call proj#config('marks.json', marks)
    endif
endf

fun! s:on_rename()
    let nname = input('New name: ')
    if len(nname)
        let marks = proj#config('marks.json')
        let name = matchstr(getline('.'), '\S\+')
        if has_key(marks, nname)
            echoerr 'Makr is exists' nname
            return 1
        endif
        let marks[nname] = marks[name]
        unlet marks[name]
        call proj#config('marks.json', marks)
    endif
endf

fun! s:show_marks()
    let marks = proj#config('marks.json')
    let ls = map(copy(marks), {k,v->printf('%s %s:%d', k, v[0], v[1])})
    call s:marks_win()
    call append(0, values(ls))
    setl noma
endf

com! ProjToggleMark call s:toggle_mark()
com! ProjMarks call s:show_marks()
