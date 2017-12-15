
" Init the variable g:Proj
fun! proj#_init(confdir)
    if !isdirectory(a:confdir)
        call mkdir(a:confdir, 'p')
    endif
    " Init the global variables
    let g:Proj = {}
    let g:Proj.workdir = fnamemodify(a:confdir, ':h')
    let g:Proj.confdir = a:confdir
    " non-block the nvim process for nvim-qt can attach it
    au VimEnter    * sil! call proj#load()
    au VimLeavePre * call proj#save()
    au BufWinEnter * call proj#loadview()
    au BufWinLeave * call proj#saveview()
    runtime! autoload/proj/*.vim
endf

" Create project in current directory
fun! proj#create()
    if exists('g:Proj')
        echoerr 'proj.vim is loaded'
    else
        return proj#_init(getcwd() . '/.vimproj')
    endif
endf

" Delete project
fun! proj#delete()
    if !exists('g:Proj')
        echoerr 'proj.vim is not loaded'
    endif
    call delete(g:Proj.file)
    call delete(g:Proj.confdir, 'rf')
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

" Save view
fun! proj#saveview()
    try
        if empty(&bt) && &fdm == 'manual'
            let o = &vop
            set vop=folds,cursor
            mkview!
            let &vop = o
        endif
    catch
        echo v:errmsg
    endt
endf

" Load view
fun! proj#loadview()
    try
        sil! loadview
    catch
        echo v:errmsg
    endt
endf

" Save project
fun! proj#save()
    if exists('g:Proj')
        do User BeforeProjSave
        call s:SaveSession()
        " echo getchar()
    endif
endf

" Load project
fun! proj#load()
    call s:LoadSession()
    let &viewdir = g:Proj['confdir'] . '/view'
    do User AfterProjLoaded
endf

" Save windows and files
fun! s:SaveSession()
    set sessionoptions=blank,help,tabpages,unix,buffers
    exe 'mks!' (g:Proj.confdir . '/session.vim')
endf

fun! s:LoadSession()
    let file = g:Proj.confdir . '/session.vim'
    if filereadable(file)
        exe 'so' file
    endif
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
