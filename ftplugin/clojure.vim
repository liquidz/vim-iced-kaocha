if exists('g:loaded_iced_kaocha')
  finish
endif
let g:loaded_iced_kaocha = 1

let s:save_cpo = &cpoptions
set cpoptions&vim

command! -nargs=+ IcedKaochaTest            call iced#kaocha#test_by_ids([<f-args>])
command!          IcedKaochaTestAll         call iced#kaocha#test_all()
command! -nargs=? IcedKaochaTestNs          call iced#kaocha#test_ns(<q-args>)
command!          IcedKaochaTestUnderCursor call iced#kaocha#test_under_cursor()
command!          IcedKaochaTestRedo        call iced#kaocha#test_redo()
command!          IcedKaochaTestRerunLast   call iced#kaocha#test_rerun_last()

nnoremap <silent> <Plug>(iced_kaocha_test_all)          :<C-u>IcedKaochaTestAll<CR>
nnoremap <silent> <Plug>(iced_kaocha_test_ns)           :<C-u>IcedKaochaTestNs<CR>
nnoremap <silent> <Plug>(iced_kaocha_test_under_cursor) :<C-u>IcedKaochaTestUnderCursor<CR>
nnoremap <silent> <Plug>(iced_kaocha_test_redo)         :<C-u>IcedKaochaTestRedo<CR>
nnoremap <silent> <Plug>(iced_kaocha_test_rerun_last)   :<C-u>IcedKaochaTestRerunLast<CR>

let &cpoptions= s:save_cpo
unlet s:save_cpo
