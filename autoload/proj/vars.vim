
fun! s:save()
    let option = {}
    let global = {}
    for i in s:vars.global
        if has_key(g:, i)
            let global[i] = g:[i]
        endif
    endfo
    for i in s:vars.option
        let option[i] = eval('&' . i)
    endfo
    call proj#config('vars.json', {'global': global, 'option': option})
endf

fun! s:loadopts()
    for [k, v] in items(s:option)
        exe 'let &'.k '= v'
    endfor
endf

fun! s:load(vars)
    for [k, v] in items(a:vars.global)
        let g:[k] = v
    endfo
    let s:option = a:vars.option
    au VimEnter * call <sid>loadopts()
endf

fun! s:init()
    let vars = proj#config('vars.json')
    if type(vars) == v:t_dict        
        let s:vars = {'global': keys(vars.global), 'option': keys(vars.option)}
        call s:load(vars)
    else                " for the first time
        let s:vars = {
            \ 'global': [],
            \ 'option': ['lines', 'columns', 'title', 'titlestring', 'viewdir']
            \ }
    endif
endf

call s:init()

au User BeforeProjSave  call <SID>save()
