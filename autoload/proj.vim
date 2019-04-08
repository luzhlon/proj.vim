
" Init the variable g:Proj
fun! proj#_init(...)
    let cwd = a:0 ? a:1 : getcwd()
    let confdir = cwd . '/.vimproj'
    if !isdirectory(confdir)
        call mkdir(confdir, 'p')
    endif
    " Init the global variables
    let g:Proj = {}
    let g:Proj.workdir = fnamemodify(confdir, ':h')
    let g:Proj.confdir = confdir
    " non-block the nvim process for nvim-qt can attach it
    au VimEnter    * nested sil! call proj#load()
    au VimLeavePre * nested try | call proj#save() | catch | call getchar() | endt
    au BufWinEnter * nested call proj#loadview()
    au BufWinLeave * nested call proj#saveview()
endf

" Create project in current directory
fun! proj#create()
    if exists('g:Proj')
        echoerr 'proj.vim is loaded'
    else
        return proj#_init()
    endif
endf

let s:history_path = glob('~') . '/.cache/vimproj_cache_dir'

fun! proj#add_history(dir)
    let dir = a:dir
    let history_dir = proj#get_history()
    if has('win32')
        let dir = substitute(dir, '\/', '\', 'g')
        call map(history_dir, {i,v->substitute(v, '\/', '\', 'g')})
    endif
    for item in history_dir
        if has('win32')
            if item ==? dir | return | endif
        else
            if item ==# dir | return | endif
        endif
    endfor
    call add(history_dir, dir)
    call writefile(history_dir, s:history_path)
endf

fun! proj#get_history()
    let cache_file = s:history_path
    return filereadable(cache_file) ? readfile(cache_file) : []
endf

" fun! proj#select_history()
"     let history_dir = proj#get_history()
"     if !len(history_dir)
"         echo 'There is no proj''s history'
"         return
"     endif

"     let g:_ = join(history_dir, "\n")
"     let r = denite#start([{'name': 'output', 'args': ['echo g:_']}])
"     let g:G = r
"     if empty(r) | return | endif
" endf

fun! proj#cd(dir)
    exec 'cd' a:dir
    call proj#_init()
    call proj#load()
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
        call proj#add_history(g:Proj['workdir'])
        do User BeforeProjSave
        call s:save_session()
        " echo getchar()
    endif
endf

" Load project
fun! proj#load()
    sil! exe 'so' g:Proj['confdir'].'/session.vim'
    sil! exe 'so' g:Proj['confdir'].'/config.vim'
    let &viewdir = g:Proj['confdir'] . '/view'
    do User AfterProjLoaded
    echom 'Proj Loaded'
endf

" Save windows and files
fun! s:save_session()
    set sessionoptions=curdir,blank,help,tabpages,unix,buffers
    exe 'mks!' (g:Proj.confdir . '/session.vim')
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

sil! runtime! autoload/proj/*.vim
