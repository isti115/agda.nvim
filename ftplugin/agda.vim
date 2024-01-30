if !exists('g:agda_keymap')
  let g:agda_keymap = "vim"
endif

if g:agda_keymap == "vim"
  nnoremap <silent> <LocalLeader>l :lua require('agda').load()<Return>
  nnoremap <silent> <LocalLeader>, :lua require('agda').goal_type_context()<Return>
  nnoremap <silent> <LocalLeader>u :lua require('agda').goal_type_context_norm()<Return>
  nnoremap <silent> <LocalLeader>. :lua require('agda').goal_type_context_infer()<Return>
  nnoremap <silent> <LocalLeader>d :lua require('agda').infer()<Return>
  nnoremap <silent> <LocalLeader>n :lua require('agda').compute()<Return>
  nnoremap <silent> <LocalLeader><Space> :lua require('agda').give()<Return>
  nnoremap <silent> <LocalLeader>c :lua require('agda').case()<Return>
  nnoremap <silent> <LocalLeader>r :lua require('agda').refine()<Return>
  nnoremap <silent> <LocalLeader>a :lua require('agda').auto()<Return>
  nnoremap <silent> <LocalLeader>f :lua require('agda').forward()<Return>
  nnoremap <silent> <LocalLeader>b :lua require('agda').back()<Return>
  nnoremap <silent> <LocalLeader>v :lua require('agda').version()<Return>
  nnoremap <silent> <LocalLeader>? :lua require('agda').goals()<Return>
endif

if g:agda_keymap == "emacs"
  nnoremap <silent> <C-c><C-l> :lua require('agda').load()<Return>
  nnoremap <silent> <C-c><C-,> :lua require('agda').goal_type_context()<Return>
  nnoremap <silent> <C-u><C-u><C-,> :lua require('agda').goal_type_context_norm()<Return>
  nnoremap <silent> <C-c><C-.> :lua require('agda').goal_type_context_infer()<Return>
  nnoremap <silent> <C-c><C-d> :lua require('agda').infer()<Return>
  nnoremap <silent> <C-c><C-n> :lua require('agda').compute()<Return>
  nnoremap <silent> <C-c><C-Space> :lua require('agda').give()<Return>
  nnoremap <silent> <C-c><C-c> :lua require('agda').case()<Return>
  nnoremap <silent> <C-c><C-r> :lua require('agda').refine()<Return>
  nnoremap <silent> <C-c><C-a> :lua require('agda').auto()<Return>
  nnoremap <silent> <C-c><C-f> :lua require('agda').forward()<Return>
  nnoremap <silent> <C-c><C-b> :lua require('agda').back()<Return>
  nnoremap <silent> <C-c><C-v> :lua require('agda').version()<Return>
  nnoremap <silent> <C-c><C-?> :lua require('agda').goals()<Return>
endif

setlocal commentstring=--\ %s
