if exists('b:current_syntax')
  finish
endif

syntax keyword agdakeyword abstract as coinductive constructor data field hiding import inductive infix infixl infixr instance module mutual open pattern primitive private public record renaming rewrite syntax using variable where with
syntax match agdacomment "--.*$"
syntax match agdasymbol ":\|→\|="

" Color schemes transformed from the highlighting file of agda-mode-vscode:
" https://github.com/banacorn/agda-mode-vscode/blob/344782ab97f23422e57d05194d59e89f5b3381c7/src/Highlighting/Highlighting__AgdaAspect.res

if !exists('g:agda_theme')
  let g:agda_theme = "dark"
endif

if g:agda_theme == "dark"
  hi agdacomment                guifg=#505050
  hi agdakeyword                guifg=#ff9932
  hi agdastring                 guifg=#dd4d4d
  hi agdanumber                 guifg=#9010e0
  hi agdasymbol                 guifg=#bfbfbf
  hi agdaprimitivetype          guifg=#8080ff
  " hi agdapragma
  " hi agdabackground
  " hi agdamarkup
  hi agdaerror                  guifg=#ff0000
  " hi agdadottedpattern
  hi agdaunsolvedmeta           guibg=#806b00
  hi agdaunsolvedconstraint     guibg=#806b00
  hi agdaterminationproblem     guibg=#802400
  hi agdapositivityproblem      guibg=#803f00
  hi agdadeadcode               guibg=#808080
  hi agdacoverageproblem        guibg=#805300
  hi agdaincompletepattern      guibg=#800080
  " hi agdatypechecks
  hi agdacatchallclause         guibg=#404040
  hi agdaconfluenceproblem      guibg=#800080
  " hi agdabound
  " hi agdageneralizable
  hi agdainductiveconstructor   guifg=#29cc29
  hi agdacoinductiveconstructor guifg=#ffea75
  hi agdadatatype               guifg=#8080ff
  hi agdafield                  guifg=#f570b7
  hi agdafunction               guifg=#8080ff
  hi agdamodule                 guifg=#cd80ff
  hi agdapostulate              guifg=#8080ff
  hi agdaprimitive              guifg=#8080ff
  hi agdarecord                 guifg=#8080ff
  " hi agdaargument
  hi agdamacro                  guifg=#73baa2
  " hi agdaoperator
  hi agdahole                   guibg=#444444
  " hi agdahole                   guibg=#1e731e
endif

if g:agda_theme == "light"
  hi agdacomment                guifg=#b0b0b0
  hi agdakeyword                guifg=#cd6600
  hi agdastring                 guifg=#b22222
  hi agdanumber                 guifg=#800080
  hi agdasymbol                 guifg=#404040
  hi agdaprimitivetype          guifg=#0000cd
  " hi agdapragma
  " hi agdabackground
  " hi agdamarkup
  hi agdaerror                  guifg=#ff0000
  " hi agdadottedpattern
  hi agdaunsolvedmeta           guibg=#ffff00
  hi agdaunsolvedconstraint     guibg=#ffff00
  hi agdaterminationproblem     guibg=#ffa07a
  hi agdapositivityproblem      guibg=#cd853f
  hi agdadeadcode               guibg=#a9a9a9
  hi agdacoverageproblem        guibg=#f5deb3
  hi agdaincompletepattern      guibg=#800080
  " hi agdatypechecks
  hi agdacatchallclause         guibg=#f5f5f5
  hi agdaconfluenceproblem      guibg=#ffc0cb
  " hi agdabound
  " hi agdageneralizable
  hi agdainductiveconstructor   guifg=#008b00
  hi agdacoinductiveconstructor guifg=#996600
  hi agdadatatype               guifg=#0000cd
  hi agdafield                  guifg=#ee1289
  hi agdafunction               guifg=#0000cd
  hi agdamodule                 guifg=#800080
  hi agdapostulate              guifg=#0000cd
  hi agdaprimitive              guifg=#0000cd
  hi agdarecord                 guifg=#0000cd
  " hi agdaargument
  hi agdamacro                  guifg=#458b74
  " hi agdaoperator
  hi agdahole                   guibg=#b4eeb4
endif
