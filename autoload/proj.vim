
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

fun! proj#cd(dir)
    sil! windo bwipe
    sil! bufdo bwipe
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
    if get(g:, 'proj_enable_view', 1)
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
    endif
endf

" Load view
fun! proj#loadview()
    if get(g:, 'proj_enable_view', 1)
        try
            sil! loadview
        catch
            echo v:errmsg
        endt
    endif
endf

fun! s:save_gui_info()
    let max = has('nvim') ? get(g:, 'GuiWindowMaximized') : (has('gui_running') && getwinposx()<0 && getwinposy()<0)
    let data = {'max': max}
    if &title && len(&titlestring)
        let data.title = &titlestring
    endif
    call proj#config('gui.json', data)
endf

fun! proj#close_specwin()
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

" Save project
fun! proj#save()
    if exists('g:Proj')
        call proj#add_history(g:Proj['workdir'])
        do User BeforeProjSave
        call s:save_gui_info()
        if get(g:, 'proj_close_specwin', 1)
            call proj#close_specwin()
        endif
        call s:save_session()
        " echo getchar()
    endif
endf

fun! s:set_title(title)
    let &titlestring = a:title
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
        call timer_start(100, {t->s:set_title(data['title'])})
        let g:titlestring = data['title']
    endif
endf

" Load project
fun! proj#load()
    call s:on_load()
    sil! exe 'so' g:Proj['confdir'].'/session.vim'
    sil! exe 'so' g:Proj['confdir'].'/config.vim'
    let &viewdir = g:Proj['confdir'] . '/view'
    do User AfterProjLoaded
    echom 'Proj Loaded'
endf

" Save windows and files
fun! s:save_session()
    for info in getbufinfo({'buflisted': 1})
        let bnr = info['bufnr']
        if len(getbufvar(bnr, '&bt'))
            sil! exec bnr 'bw!'
        endif
    endfor
    set sessionoptions=blank,help,tabpages,unix,buffers,winsize
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
