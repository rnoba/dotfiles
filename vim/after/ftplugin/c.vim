if exists("customc")
  finish
endif
let customc = 1 

setlocal makeprg=./Buildfile

function CreateTags()
  let root = getcwd()
  exec ':!ctags -R --exclude=log -f ./tags *'
endfunction

nnoremap <Leader>n :cnext<CR>
nnoremap <Leader>p :cprev<CR>
nnoremap <Leader>s :copen<CR>
nnoremap <Leader>cc :cclose<CR>
nnoremap <silent> <Leader>tt :call CreateTags()<CR>
