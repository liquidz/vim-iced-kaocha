if exists('g:loaded_iced_kaocha')
  finish
endif
let g:loaded_iced_kaocha = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command!          IcedKaochaTestAll call iced#kaocha#test_all()
command! -nargs=? IcedKaochaTestNs  call iced#kaocha#test_ns(<q-args>)
command!          IcedKaochaTest    call iced#kaocha#test_under_cursor()
command!          IcedKaochaRetest  call iced#kaocha#retest()

let &cpoptions= s:save_cpo
unlet s:save_cpo
