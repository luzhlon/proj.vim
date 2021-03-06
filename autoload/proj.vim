
" Init the variable g:Proj
fun! proj#_init(...)
    let cwd = a:0 ? a:1 : getcwd()
    let confdir = proj#confdir(cwd)
    if !isdirectory(confdir)
        call mkdir(confdir, 'p')
    endif
    " Init the global variables
    let g:Proj = {}
    let g:Proj.workdir = fnamemodify(confdir, ':h')
    let g:Proj.confdir = confdir
    " non-block the nvim process for nvim-qt can attach it
    au VimEnter    * nested sil! call proj#load()
    au VimLeavePre * nested call proj#try_save()
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

    " 将最近添加的移到列表头部
    for i in range(0, len(history_dir) - 1)
        let item = get(history_dir, i, '')
        if has('win32') ? item ==? dir: item ==# dir
            call remove(history_dir, i)
        endif
        " 移除不存在的目录
        if len(item) && !isdirectory(item)
            call remove(history_dir, i)
        endif
    endfor
    call insert(history_dir, dir, 0)
    call writefile(history_dir, s:history_path)
endf

fun! proj#get_history()
    let cache_file = s:history_path
    return filereadable(cache_file) ? readfile(cache_file) : []
endf

fun! proj#startify_entries()
    return map(proj#get_history()[0:10], {i,v->{'cmd': 'ProjCD', 'path': v, 'line': v}})
endf

fun! proj#confdir(...)
    if a:0
        return a:1 . (has('win32') ? '\': '/') . g:proj#dirname
    else
        return g:Proj['confdir']
    endif
endf

fun! proj#cd(dir)
    sil! windo bwipe
    sil! bufdo bwipe
    exec 'cd' a:dir
    call proj#_init()
    call proj#load()
endf

fun! proj#try_cd(dir)
    if has_key(g:, 'Proj') | return | endif
    let confdir = proj#confdir(a:dir)
    if isdirectory(confdir)
        call proj#cd(a:dir)
    else
        echo confdir 'Not Exists'
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
    let file = g:Proj.confdir . (has('win32') ? '\': '/') . a:file
    if a:0
        return s:writejson(file, a:1)
    else
        return s:readjson(file)
    endif
endf

" Save view
fun! proj#saveview()
    if get(g:, 'proj#enable_view')
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

fun! s:buf_line_name(info)
    let v = a:info
    return '+' . v['lnum'] . ' ' . fnamemodify(v['name'], ':.')
endf

fun! s:save_info()
    let max = has('nvim') ? get(g:, 'GuiWindowMaximized') : (has('gui_running') && getwinposx()<0 && getwinposy()<0)
    let data = {'max': max}
    if &title && len(&titlestring)
        let data.title = &titlestring
    endif

    " All Buffers
    let data.buffers = map(filter(getbufinfo({'buflisted': 1}),
                                \ {i,v->empty(getbufvar(v['bufnr'], '&bt')) && len(v['name'])}),
                         \ {i,v->s:buf_line_name(v)})

    " Current Buffer
    for i in range(1, winnr('$'))
        let bnr = winbufnr(i)
        if empty(&bt)
            let data.current = s:buf_line_name(getbufinfo(bufnr('%'))[0])
            break
        elseif empty(getbufvar(bnr, '&bt'))
            let data.current = s:buf_line_name(getbufinfo(bnr)[0])
            break
        endif
    endfor

    call proj#config('gui.json', data)
endf

fun! proj#close_specwin()
    let cur_wid = win_getid()
    for i in range(1, winnr('$'))
        " Close the special window(buffer)
        if len(getbufvar(winbufnr(i), '&bt'))
            call win_gotoid(win_getid(i))
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

fun! proj#try_save()
    try
        call proj#save()
    catch
        echoerr v:throwpoint v:exception
        call getchar()
    endt
endf

" Save project
fun! proj#save()
    if exists('g:Proj')
        do User BeforeProjSave
        call s:save_info()
        if get(g:, 'proj_close_specwin', 1)
            call proj#close_specwin()
        endif
        call s:save_session()
        call proj#add_history(g:Proj['workdir'])
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

    for path in get(data, 'buffers', [])
        exec 'badd' path
    endfor

    " Empty buffer [No Name]
    if empty(expand('%')) && !&modified && line('$') <= 1 && empty(getline(1))
        set bh=wipe
    endif

    if has_key(data, 'current')
        exec 'edit' data['current']
    endif
endf

" Load project
fun! proj#load()
    sil! exe 'so' g:Proj['confdir'].'/session.vim'
    call s:on_load()
    sil! exe 'so' g:Proj['confdir'].'/config.vim'
    let &viewdir = g:Proj['confdir'] . '/view'
    do User AfterProjLoaded
    call proj#add_history(g:Proj['workdir'])
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
    set sessionoptions=blank,help,tabpages,unix,winsize
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
