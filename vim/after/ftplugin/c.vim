if exists("customc")
  finish
endif
let customc = 1 

setlocal makeprg=./Buildfile

function CreateTags()
  let root = getcwd()
  exec ':!ctags -R --exclude=log -f ./tags *'
endfunction

nnoremap <silent> <Leader>n :cnext<CR>
nnoremap <silent> <Leader>sf :FZF<CR>
nnoremap <silent> <Leader>p :cprev<CR>
nnoremap <silent> <Leader>s :copen<CR>
nnoremap <silent> <Leader>cc :cclose<CR>
nnoremap <silent> <Leader>tt :call CreateTags()<CR>
