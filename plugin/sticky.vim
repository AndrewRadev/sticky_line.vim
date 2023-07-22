if exists('g:loaded_sticky') || &cp
  finish
endif

let g:loaded_sticky = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

command! -range -bang Sticky call sticky#Pin(<line1>, <line2>, <q-bang>)

augroup Sticky
  autocmd!
  autocmd WinScrolled,VimResized,QuitPre,WinEnter,FocusGained *
        \ call sticky#Redraw()
  autocmd WinLeave,BufLeave,BufWinLeave,FocusLost *
        \ call sticky#Reset()
augroup END

sign define StickyPin text=📌 texthl=Comment

let &cpo = s:keepcpo
unlet s:keepcpo
