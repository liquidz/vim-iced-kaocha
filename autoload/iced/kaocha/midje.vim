let s:save_cpo = &cpoptions
set cpoptions&vim

let s:code = join([
     \ '(let [facts (midje.config/with-augmented-config {:check-after-creation false',
     \ '                                                 :print-level :print-nothing}',
     \ '              (midje.repl/load-facts ''%s)',
     \ '              (midje.repl/fetch-facts ''%s))]',
     \ '  (->> facts',
     \ '       (map meta)',
     \ '       (filter #(= "%s" (:midje/name %%)))',
     \ '       first',
     \ '       :midje/guid))',
     \ ], "\n")

function! iced#kaocha#midje#testable_id(ns, test_name, callback) abort
  let code = printf(s:code, a:ns, a:ns, a:test_name)
  let res = iced#eval_and_read(code)

  if !has_key(res, 'value') || empty(res['value'])
    return iced#message#error_str('Failed to fetch fact''s guid.')
  endif

  call a:callback(printf('%s/%s', a:ns, res['value']))
endfunction


let &cpoptions = s:save_cpo
unlet s:save_cpo
