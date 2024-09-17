if !exists('#WinScrolled')
  finish
endif

if exists('g:loaded_sticky_line') || &cp
  finish
endif

let g:loaded_sticky_line = '0.0.1' " version number
let s:keepcpo = &cpo
set cpo&vim

command! -range -bang StickyLine call sticky_line#Pin(<line1>, <line2>, <q-bang>)

augroup StickyLine
  autocmd!
  autocmd WinScrolled,VimResized,WinResized,WinEnter,FocusGained *
        \ call sticky_line#Redraw()
  autocmd QuitPre *
        \ call sticky_line#Reset()
augroup END

sign define StickyLinePin text=📌 texthl=Comment linehl=Pmenu

let &cpo = s:keepcpo
unlet s:keepcpo
