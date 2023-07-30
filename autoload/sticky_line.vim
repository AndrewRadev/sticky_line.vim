function! sticky_line#Pin(line1, line2, bang) abort
  if !exists('b:sticky_popups') | let b:sticky_popups = [] | endif

  let sticky_lines = s:GroupSequentialLines(s:GetLinesFromSigns())

  if a:bang == '!'
    call sticky_line#Reset()
  else
    call add(sticky_lines, [a:line1, a:line2])
    let sticky_lines = s:SortAndMerge(sticky_lines)

    for line in range(a:line1, a:line2)
      call sign_place(0, 'StickyLine', 'StickyLinePin', bufnr(), { 'lnum': line })
    endfor

    call sticky_line#Redraw()
  endif
endfunction

function! sticky_line#Redraw() abort
  let sticky_lines = s:GroupSequentialLines(s:GetLinesFromSigns())

  let offset = 0
  call s:ClosePopups()

  for [line1, line2] in sticky_lines
    if line1 >= line('w0') | continue | endif

    let line_count = line2 - line1 + 1
    let [window_row, window_col] = win_screenpos(0)

    let popup = popup_create(bufnr(), {
          \ 'minwidth':  winwidth(0),
          \ 'maxwidth':  winwidth(0),
          \ 'line':      window_row + offset,
          \ 'col':       window_col,
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

function! sticky_line#Reset() abort
  call s:ClosePopups()
  call sign_unplace('StickyLine', { 'buffer': bufnr() })
endfunction

function! s:GetLinesFromSigns() abort
  let signs = sign_getplaced(bufnr(), { 'group': 'StickyLine' })[0].signs
  let signs = filter(signs, { _, sign -> sign.name ==# 'StickyLinePin' })

  return map(signs, { _, sign -> sign.lnum })
endfunction

function! s:GroupSequentialLines(lines) abort
  if len(a:lines) == 0
    return []
  endif

  let groups = [[a:lines[0], a:lines[0]]]

  for lnum in a:lines[1:]
    if lnum == groups[-1][1] + 1
      let groups[-1][1] = lnum
    else
      call add(groups, [lnum, lnum])
    endif
  endfor

  return groups
endfunction

function! s:ClosePopups() abort
  for popup in get(b:, 'sticky_popups', [])
    call popup_close(popup)
  endfor

  let b:sticky_popups = []
endfunction

function! s:SortAndMerge(items) abort
  if len(a:items) == 0
    return a:items
  endif

  let items = sort(a:items, function('s:SortPairs'))
  let result = [items[0]]

  for [start, end] in items[1:]
    let previous_end = result[-1][1]

    if start <= previous_end && end <= previous_end
      " We can ignore this one, it's inside
    elseif start <= previous_end
      " We update the previous item's end to merge these
      let result[-1][1] = end
    else
      call add(result, [start, end])
    endif
  endfor

  return result
endfunction

function! s:SortPairs(left, right) abort
  let [left_start, left_end]   = a:left
  let [right_start, right_end] = a:right

  if left_start > right_start
    return 1
  elseif left_start < right_start
    return -1
  elseif left_end > right_end
    return 1
  elseif left_end < right_end
    return -1
  else
    return 0
  endif
endfunction

function! sticky_line#Test()
  call assert_equal([[1, 3]], s:SortAndMerge([[1, 2], [2, 3]]))
  call assert_equal([[1, 2], [3, 4]], s:SortAndMerge([[1, 2], [3, 4]]))
  call assert_equal([[1, 2], [3, 4]], s:SortAndMerge([[3, 4], [1, 2]]))
  call assert_equal([[10, 20]], s:SortAndMerge([[10, 20], [10, 20]]))
  call assert_equal([[10, 20]], s:SortAndMerge([[10, 20], [11, 20]]))
  call assert_equal([[9, 20]], s:SortAndMerge([[10, 20], [9, 15]]))

  call assert_equal([], s:GroupSequentialLines([]))
  call assert_equal([[1, 1]], s:GroupSequentialLines([1]))
  call assert_equal(
        \ [[1, 3], [5, 7], [9, 12]],
        \ s:GroupSequentialLines([1, 2, 3, 5, 6, 7, 9, 10, 11, 12])
        \ )

  for e in v:errors
    echo e
  endfor

  let v:errors = []
endfunction
