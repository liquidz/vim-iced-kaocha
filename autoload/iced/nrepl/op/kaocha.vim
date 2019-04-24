let s:save_cpo = &cpoptions
set cpoptions&vim

function! iced#nrepl#op#kaocha#test_all(callback) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  call iced#nrepl#send({
        \ 'id': iced#nrepl#id(),
        \ 'op': 'kaocha-test-all',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ })
endfunction

function! iced#nrepl#op#kaocha#test(option, callback) abort
  if !iced#nrepl#is_connected()
    return iced#message#error('not_connected')
  endif

  let msg = {
        \ 'id': iced#nrepl#id(),
        \ 'op': 'kaocha-test',
        \ 'sesion': iced#nrepl#current_session(),
        \ 'callback': a:callback,
        \ }
  call extend(msg, a:option)

  call iced#nrepl#send(msg)
endfunction

" register op response handler
for op in ['kaocha-test-all', 'kaocha-test']
  call iced#nrepl#register_handler(op, function('iced#nrepl#extend_responses_handler'))
endfor

let &cpoptions = s:save_cpo
unlet s:save_cpo
