nnoremap <silent> <C-c><C-l> :lua require('agda').load()<Return>
nnoremap <silent> <C-c><C-,> :lua require('agda').goal_type_context()<Return>
nnoremap <silent> <C-c><C-c> :lua require('agda').case()<Return>
nnoremap <silent> <C-c><C-r> :lua require('agda').refine()<Return>
nnoremap <silent> <C-c><C-a> :lua require('agda').auto()<Return>
nnoremap <silent> <C-c><C-f> :lua require('agda').forward()<Return>
nnoremap <silent> <C-c><C-b> :lua require('agda').back()<Return>
nnoremap <silent> <C-c><C-v> :lua require('agda').version()<Return>
