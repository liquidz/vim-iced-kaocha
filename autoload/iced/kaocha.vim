let s:save_cpo = &cpoptions
set cpoptions&vim

let s:last_test = {}

function! s:out(resp) abort
  call iced#nrepl#test#done(
        \ iced#nrepl#test#clojure_test#parse(a:resp))
endfunction

function! s:take_from_sexp(expr, n) abort
  let res = []
  let tmp = ''
  let expr_count = 0
  let mode = 'default'

  for idx in range(len(a:expr))
    if expr_count >= a:n
      break
    endif

    let c = a:expr[idx]
    if mode ==# 'default'
      if c ==# '(' || c ==# ' ' || c ==# "\r" || c ==# "\n"
        if !empty(tmp)
          call add(res, tmp)
          let tmp = ''
          let expr_count = expr_count + 1
        endif
        continue
      endif
    elseif mode ==# 'string'
      if c ==# '"'
        call add(res, tmp)
        let mode = 'default'
        let tmp = ''
        let expr_count = expr_count + 1
        continue
      endif
    endif

    if c ==# '"'
      let mode = 'string'
      let tmp = ''
      continue
    endif

    let tmp = tmp . c
  endfor

  return res
endfunction

function! s:lang_prefix() abort
  let ext = expand('%:e')
  let sess_key = iced#nrepl#current_session_key()

  " c.f. https://github.com/lambdaisland/kaocha-cljs/blob/v0.0-59/src/kaocha/type/cljs.clj#L38-L51
  return (ext ==# 'cljs' || sess_key ==# 'cljs')
        \ ? 'cljs:' : ''
endfunction

function! s:extract_testable_id(ns, code, callback) abort
  let code =  substitute(a:code, '[\r\n]\+', ' ', 'g')
  let code =  substitute(code, '\s\+', ' ', 'g')
  let head_two = s:take_from_sexp(code, 2)

  if len(head_two) != 2
    return ''
  endif

  let fn = substitute(head_two[0], '^[^/]\+/', '', '')
  let first_arg = head_two[1]

  if fn ==# 'deftest'
    " clojure.test
    let prefix = s:lang_prefix()
    call iced#nrepl#ns#require(a:ns, {_ ->
          \ a:callback(printf('%s%s/%s', prefix, a:ns, first_arg))})
  elseif fn ==# 'facts' || fn ==# 'fact'
    " midje
    call iced#nrepl#ns#eval({_ ->
          \ iced#nrepl#ns#require('midje.config', {_ ->
          \   iced#nrepl#ns#require('midje.repl', {_ ->
          \     iced#kaocha#midje#testable_id(a:ns, first_arg, a:callback)
          \ })})})
  else
    " unknown
    return ''
  endif
endfunction

function! s:is_empty_array(arr) abort
  if empty(a:arr)
    return v:true
  endif

  for x in a:arr
    if empty(x)
      return v:true
    endif
  endfor

  return v:false
endfunction

function! iced#kaocha#test_by_ids(ids, ...) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  if s:is_empty_array(a:ids)
    return iced#message#error('not_found')
  endif

  let option = get(a:, 1, {})
  let option['testable-ids'] = map(copy(a:ids), {_, id -> trim(id, ':')})

  let s:last_test = {'type': 'id', 'ids': option['testable-ids']}

  call iced#nrepl#op#kaocha#test(option, funcref('s:out'))
endfunction

function! s:test_under_cursor(ns, code) abort
  call s:extract_testable_id(a:ns, a:code, {id ->
        \ iced#kaocha#test_by_ids([id], {'ns': a:ns})})
endfunction

function! iced#kaocha#test_under_cursor() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let ns = iced#nrepl#ns#name()
  let ctl = iced#paredit#get_current_top_object('(', ')')
  call s:test_under_cursor(ns, ctl['code'])
endfunction

function! iced#kaocha#test_ns(ns) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let ns = empty(a:ns) ? iced#nrepl#ns#name() : a:ns

  call iced#nrepl#ns#require(ns, {_ -> iced#kaocha#test_by_ids([ns])})
endfunction

function! iced#kaocha#test_all() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif

  let s:last_test = {'type': 'all'}

  call iced#nrepl#op#cider#ns_load_all({_ -> iced#nrepl#op#kaocha#test_all(funcref('s:out'))})
endfunction

function! iced#kaocha#test_redo() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#op#kaocha#retest(funcref('s:out'))
endfunction

function! iced#kaocha#test_rerun_last() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  if empty(s:last_test) | return iced#message#error('not_found') | endif

  let test_type = s:last_test['type']
  if test_type ==# 'id'
    call iced#kaocha#test_by_ids(s:last_test['ids'])
  elseif test_type ==# 'all'
    call iced#kaocha#test_all()
  else
    return iced#message#error_str('Invalid test type')
  endif
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
