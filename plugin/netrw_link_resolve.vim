" On opening symlink via netrw, wipes buffer and reopens at real path.
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-netrw-link-resolve
" License: https://creativecommons.org/publicdomain/zero/1.0/
" vim:tw=0:ts=2:sw=2:et:norl:ft=vim

" YOU: Uncomment the 'unlet', then <F9> to reload this file.
"       https://github.com/landonb/vim-source-reloader
"  silent! unlet g:loaded_netrw_link_resolve

" NOTE: There's an open issue with using g:Netrw_funcref as List, which we
" workaround by including a patched copy of netrw.vim in this project. But
" if upstream is fixed and we want to remove that patch, we would later
" want to check the version here, e.g.,
"   if exists("g:loaded_netrw_link_resolve") || &cp || v:version < 802
if exists("g:loaded_netrw_link_resolve") || &cp
  finish
endif
let g:loaded_netrw_link_resolve = 1

" Mechanism to close opened file if opened at symlink path, and reopen at real path.
"
" - I've seen more basic, but broken, examples of how to do this, e.g.,
"       command! FollowSymlink execute "file " . resolve(expand("%")) | edit
"   but this approach has a glaring problem: if does not delete and wipe
"   the symlink buffer, so Vim thinks it has two buffers open to the same
"   file. So when you try to save, it fails, and Vim gripes:
"       E13: File exists (add ! to override)
" - So open a new buffer, delete (technically, Wipe!) the old buffer (i.e.,
"   call `bw`, not `bd` -- if you :bd the symlink and open the canonical path,
"   Vim will open the symlink path, so weird!), and then call :edit with the
"   canonical path.
"   - Ref: Trying to buffer-delete (:bd) a symlink vs. buf-wiping (:bw), see:
"     https://superuser.com/questions/960773/vim-opens-symlink-even-when-given-target-path-directly
" - Note that I tried hooking `BufRead *` but, for whatever reason, upon open,
"   the &filetype would be unset (or at least that's what I noticed before
"   trying a different approach; so I did not diagnose further).
"   - Which means this feature only applies to files opened through netrw.
"     So you can still open symlinks other ways, e.g., via `:edit`.
" - The main reason I built this plugin was because I like to maintain
"   directories of symlinks to commonly edited notes files. Then I've got
"   a <Leader> command mapped to `:Explore /path/to/my/symlinks`. This plugin
"   ensures that I can open any file from either its syumlink, or using its
"   canonical path, and Vim won't 'File-exists' me.

function! s:PopBufSurfHistory()
  if !exists("w:history") || (len(w:history) <= 0)
    return
  endif
  call remove(w:history, w:history_index)
  let w:history_index -= 1
endfunction

function! FollowSymlinkAndCleanupBufSurfHistory()
  " Use '%:p' for full path, as opposed to possibly relative '%' path.
  let l:sympath = expand('%:p')
  " Check if file type is a symlink, and resolve to canonical path if so.
  if getftype(l:sympath) == 'link'
    " Resolve the file path and open the "actual" file.
    let l:canpath = resolve(l:sympath)
    " Check if the canonical path is different than what was opened.
    if l:sympath != l:canpath
      " Remove the symlink buffer.
      call s:PopBufSurfHistory()
      " Open a temporary new buffer, to wipe the old one.
      enew
      " Remove the enew buffer from BufSurf history.
      call s:PopBufSurfHistory()
      " Note: Wipe the buffer, not delete, lest Vim re-open file at symlink path!
      " - WRONG: exe "bd " . l:sympath
      exe "bw " . l:sympath
      " Almost done: Open the file using its real path.
      exe "edit " . l:canpath
      " Now we can be done: Remove enew from the buffer list as well.
    endif
  endif
endfunction

" ***

" Add function to netrw post-edit callback list (which could be undef or atom).
" - LATER/2020-03-21: There's an open issue in Vim's netrw.vim which breaks when
"   g:Netrw_funcref is a List -- but we should not use g:Netrw_funcref as just a
"   function ref., because then another plugin cannot also hook the callback! So
"   to play nice with others, we must treat that value as a List.
"   - (lb): In any case, I made a local, fixed copy of netrw.vim. Nothing you
"     gotta worry about, just a reminder to someday remove the local, overriding
"     copy of autoload/netrw.vim once it's fixed upstream.
function! s:NetrwSetupCallback()
  if !exists("g:Netrw_funcref")
    let g:Netrw_funcref = []
  elseif type(g:Netrw_funcref) != v:t_list
    let g:Netrw_funcref = [g:Netrw_funcref]
  endif

  let g:Netrw_funcref += [function("FollowSymlinkAndCleanupBufSurfHistory")]
endfunction

call s:NetrwSetupCallback()

