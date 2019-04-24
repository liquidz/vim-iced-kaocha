let s:save_cpo = &cpoptions
set cpoptions&vim

let s:code = join([
     \ '(do (clojure.core/require ''midje.data.compendium)',
     \ '    (let [facts (some-> @midje.data.compendium/global',
     \ '                        :by-namespace',
     \ '                        (get ''%s))]',
     \ '      (->> facts',
     \ '           (map meta)',
     \ '           (filter #(= "%s" (:midje/name %%)))',
     \ '           first',
     \ '           :midje/guid)))',
     \ ], "\n")

function! iced#kaocha#midje#testable_id(ns, test_name) abort
  if !iced#nrepl#ns#does_exist('midje.data.compendium')
    return iced#message#error_str('FIXME midje not found.')
  endif

  let code = printf(s:code, a:ns, a:test_name)
  let res = iced#eval_and_read(code)

  if !has_key(res, 'value') || empty(res['value'])
    return iced#message#error_str('Failed to fetch fact''s guid.')
  endif

  return printf('%s/%s', a:ns, res['value'])
endfunction

let &cpoptions = s:save_cpo
unlet s:save_cpo
