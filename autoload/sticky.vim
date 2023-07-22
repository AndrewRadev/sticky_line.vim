function! sticky#Pin(line1, line2, bang) abort
  if !exists('b:sticky_lines')  | let b:sticky_lines  = [] | endif
  if !exists('b:sticky_popups') | let b:sticky_popups = [] | endif

  if a:bang == '!'
    call sticky#Reset()
  else
    call add(b:sticky_lines, [a:line1, a:line2])

    for line in range(a:line1, a:line2)
      call sign_place(0, '', 'StickyPin', bufnr(), { 'lnum': line })
    endfor

    " TODO (2023-07-22) Merge and dedup
    call sort(b:sticky_lines)
    call sticky#Redraw()
  endif
endfunction

function! sticky#Redraw() abort
  let offset = 0
  call s:ClosePopups()

  for [line1, line2] in get(b:, 'sticky_lines', [])
    if line1 >= line('w0') | continue | endif

    let line_count = line2 - line1 + 1
    let [window_row, window_col] = win_screenpos(0)

    let popup = popup_create(bufnr(), {
          \ 'minwidth': winwidth(0),
          \ 'maxwidth': winwidth(0),
          \ 'line': window_row + offset,
          \ 'col': window_col,
          \ 'firstline': line1,
          \ 'minheight': line_count,
          \ 'maxheight': line_count,
          \ 'scrollbar': 0,
          \ })
    if &number
      call win_execute(popup, 'set number')
    endif

    call add(b:sticky_popups, popup)
    let offset += line_count
  endfor
endfunction

function! sticky#Reset() abort
  call s:ClosePopups()

  let b:sticky_lines = []
endfunction

function! s:ClosePopups() abort
  for popup in get(b:, 'sticky_popups', [])
    call popup_close(popup)
  endfor

  let b:sticky_popups = []
endfunction
