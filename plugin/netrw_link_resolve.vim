" On opening symlink via netrw, wipes buffer and reopens at real path.
" Author: Landon Bouma <https://tallybark.com/>
" Online: https://github.com/landonb/vim-netrw-link-resolve
" License: https://creativecommons.org/publicdomain/zero/1.0/
" vim:tw=0:ts=2:sw=2:et:norl:ft=vim

" -------------------------------------------------------------------

" GUARD: Press <F9> to reload this plugin (or :source it).
" - Via: https://github.com/embrace-vim/vim-source-reloader#↩️

" NOTE: There's a bug (a variable typo author submitted patch on) in
"       earlier versions of Vim which affects using g:Netrw_funcref
"       as List.
" The bug was fixed in commit 89a9c15, one commit before patch 8.2.3386.
" - One solution is to include a recent copy of netrw.vim in this project.
" - Another solution is to demand that the user's Vim includes the fix.
" The second solution is ideal, but for some unfortunate users (those on
" older distros, especially, or those that haven't built from source in
" a while), it might require that they build their own binary, or find
" one from a different source.
" - E.g., the author's Linux Mint 19.3 on 2022-09-24 shows a version that
"   has the bug: `apt show vim` → 'Version: 2:8.0.1453-1ubuntu1.9'.
"   (But I've been building from sources for a number of years now; mostly
"    because I like to replace the Vim alt-tab icon with Burglar Bender.)
" NOTE: The traditional version check is, e.g., `v:version < 900`,
"       but you can be patch level-specific using `has()`.

if expand('%:p') ==# expand('<sfile>:p')
  unlet! g:loaded_netrw_link_resolve
endif

if exists('g:loaded_netrw_link_resolve') || &cp || !(has('nvim') || has('patch-8.2.3386'))

  finish
endif

let g:loaded_netrw_link_resolve = 1

" -------------------------------------------------------------------

" Mechanism to close opened file if opened at symlink path, and reopen at real path.
"
" - I've seen more basic, but broken, examples of how to do this, e.g.,
"       command! FollowSymlink execute "file " . resolve(expand("%")) | edit
"   but this approach has a glaring problem: it does not delete and wipe
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

function! FollowSymlinkAndCleanupBufSurfHistory()
  " Use '%:p' for full path, as opposed to possibly relative '%' path.
  let l:sympath = expand('%:p')
  " Check if file type is a symlink, and resolve to canonical path if so.
  if getftype(l:sympath) == 'link'
    " Resolve the file path and open the "actual" file.
    let l:canpath = resolve(expand(l:sympath))
    " Check if the canonical path is different than what was opened.
    if l:sympath != l:canpath
      " Open a temporary new buffer, to wipe the old one.
      enew
      " Note: Wipe the buffer, not delete, lest Vim re-open file at symlink path!
      " - WRONG: exe "bd " . l:sympath
      exe "bw " . l:sympath
      " Almost done: Open the file using its real path.
      " - DUNNO: (n)vim discards the "enew" buffer if you "edit" another path
      "   without having touched the "enew" buffer. (Which seems unexpected,
      "   and I cannot find documented; and while hidden=1, bufhidden is "".)
      exe "edit " . l:canpath
      " Now we can be done: Remove enew from the buffer list as well.
    endif
  endif
endfunction

" ***

" Add function to netrw post-edit callback list (which could be undef or atom).
" - HSTRY/2022-09-24: From 2020-03-21 until now, this plugin shipped with a
"   local copy of netrw.vim to work around an old bug that happeneed when
"   g:Netrw_funcref was a List — fixed in Vim that has('patch-8.2.3386').
"   - Beware not to use g:Netrw_funcref as just a function ref., because
"     then another plugin cannot also hook the callback. To play nice with
"     others, treat g:Netrw_funcref as a List.
function! s:NetrwSetupCallback()
  if !exists("g:Netrw_funcref")
    let g:Netrw_funcref = []
  elseif type(g:Netrw_funcref) != v:t_list
    let g:Netrw_funcref = [g:Netrw_funcref]
  endif

  let g:Netrw_funcref += [function("FollowSymlinkAndCleanupBufSurfHistory")]
endfunction

call s:NetrwSetupCallback()

