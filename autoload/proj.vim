" Create project in current directory
fun! proj#create()
    if exists('g:Proj')
        echoerr 'There is a project file exists'
    else
        let g:Proj = {'default': {
            \ 'global': [],
            \ 'option': ['lines', 'columns', 'title', 'titlestring', 'ft']
            \ }}
        let file = fnamemodify('.vimpro.json', ':p')
        let g:Proj.file = file
        let g:Proj.dir = fnamemodify(file, ':h')
        call s:CheckConfdir()
        call s:writejson(g:Proj.file, g:Proj.default)
        au VimLeavePre * call proj#save()
    endif
endf
" Delete project
fun! proj#delete()
    call delete(g:Proj.file)
    call delete(g:Proj.confdir, 'd')
    unlet g:Proj
endf
" Read/Write the config from/to file from project's config directory
fun! proj#config(file, ...)
    let file = g:Proj.confdir . '/' . a:file
    if a:0
        return s:writejson(file, a:1)
    else
        return s:readjson(file)
    endif
endf
" Save project
fun! proj#save()
    if exists('g:Proj')
        call s:CheckConfdir()
        do User BeforeProjSave
        call s:SaveVariables()
        call s:SaveSession()
    endif
endf
" Load project
fun! proj#load()
    let g:Proj.default = s:readjson(g:Proj.file)
    call s:CheckConfdir()
    call s:LoadSession()
    call s:LoadVariables()
    do User AfterProjLoaded
endf
" If config directory is not exists, create it
fun! s:CheckConfdir()
    if !has_key(g:Proj, 'confdir')
        let g:Proj.confdir = g:Proj.dir . '/.vimproj'
    endif
    if !isdirectory(g:Proj.confdir)
        call mkdir(g:Proj.confdir, 'p')
    endif
endf
" Save windows and files
fun! s:SaveSession()
    set sessionoptions=blank,help,tabpages,winpos,unix,buffers
    exe 'mks!' (g:Proj.confdir . '/session.vim')
endf
fun! s:LoadSession()
    let file = g:Proj.confdir . '/session.vim'
    if filereadable(file)
        exe 'so' file
    endif
endf
" Save variables
fun! s:SaveVariables()
    let global = {}
    let option = {}
    for i in g:Proj.default.global
        if has_key(g:, i)
            let global[i] = g:[i]
        endif
    endfo
    for i in g:Proj.default.option
        let option[i] = eval('&' . i)
    endfo
    " Save variables and options
    let vars = { 'global': global, 'option': option }
    call proj#config('vars.json', vars)
endf
fun! s:LoadVariables()
    let vars = proj#config('vars.json')
    if empty(vars)|return|endif
    call extend(g:, vars.global)
    for [k, v] in items(vars.option)
        exe 'let &'.k '= v'
    endfor
endf

fun! s:readjson(file)
    let file = a:file
    if !filereadable(file)|return 0|endif
    return json_decode(join(readfile(file)))
endf

fun! s:writejson(file, data)
    let file = a:file
    return writefile([json_encode(a:data)], file)
endf
