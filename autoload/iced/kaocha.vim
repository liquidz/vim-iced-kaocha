let s:save_cpo = &cpoptions
set cpoptions&vim

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

function! s:extract_testable_id(ns, code) abort
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
    return printf('%s/%s', a:ns, first_arg)
  elseif fn ==# 'facts' || fn ==# 'fact'
    " midje
    return iced#kaocha#midje#testable_id(a:ns, first_arg)
  else
    " unknown
    return ''
  endif
endfunction

function! s:test_under_cursor(ns, code) abort
  let testable_id = s:extract_testable_id(a:ns, a:code)
  if empty(testable_id)
    return iced#message#error('not_found')
  endif

  let option = {'ns': a:ns, 'testable-ids': [testable_id]}
  call iced#nrepl#op#kaocha#test(option, funcref('s:out'))
endfunction

function! iced#kaocha#test_under_cursor() abort
  let ns = iced#nrepl#ns#name()
  let ctl = iced#paredit#get_current_top_list()
  call iced#nrepl#ns#require(ns, {_ -> s:test_under_cursor(ns, ctl['code'])})
endfunction

function! iced#kaocha#test_ns(ns) abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  let ns = empty(a:ns) ? iced#nrepl#ns#name() : a:ns
  let option = {'testable-ids': [ns]}

  call iced#nrepl#ns#require(ns, {_ -> iced#nrepl#op#kaocha#test(option, funcref('s:out'))})
endfunction

function! iced#kaocha#test_all() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  call iced#nrepl#op#cider#ns_load_all({_ -> iced#nrepl#op#kaocha#test_all(funcref('s:out'))})
endfunction

function! iced#kaocha#retest() abort
  if !iced#nrepl#is_connected() | return iced#message#error('not_connected') | endif
  "call iced#nrepl#op#cider#ns_load_all({_ -> iced#nrepl#op#kaocha#retest(funcref('s:out'))})
  call iced#nrepl#op#kaocha#retest(funcref('s:out'))
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
