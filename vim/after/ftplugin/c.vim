if exists("customc")
  finish
endif
let customc = 1 

setlocal makeprg=./Buildfile

function CreateTags()
  let root = getcwd()
  exec ':!ctags -R --exclude=log -f ./tags *'
endfunction

nnoremap <silent> <Leader>tt :call CreateTags()<CR>
