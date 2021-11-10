<div align="center">
  <img src="assets/agda.nvim.png" width="250" />
</div>

# agda.nvim
NeoVim plugin for interacting with Agda written in Lua

## Dependencies
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### Plug
```
  Plug 'nvim-lua/plenary.nvim'
  Plug 'isti115/agda.nvim'
```

## Usage
The following default mappings are added:
```
nnoremap <silent> <C-c><C-l> :lua require('agda').load()<Return>
nnoremap <silent> <C-c><C-,> :lua require('agda').goal_type_context()<Return>
nnoremap <silent> <C-c><C-.> :lua require('agda').goal_type_context_infer()<Return>
nnoremap <silent> <C-c><C-Space> :lua require('agda').give()<Return>
nnoremap <silent> <C-c><C-c> :lua require('agda').case()<Return>
nnoremap <silent> <C-c><C-r> :lua require('agda').refine()<Return>
nnoremap <silent> <C-c><C-a> :lua require('agda').auto()<Return>
nnoremap <silent> <C-c><C-f> :lua require('agda').forward()<Return>
nnoremap <silent> <C-c><C-b> :lua require('agda').back()<Return>
nnoremap <silent> <C-c><C-v> :lua require('agda').version()<Return>
```

## Features

### Done\*
- Goal types
- Version info
- Case splitting
- Context
- Syntax highlighting
- Refinement
- Auto
- Infer type of goal contents
- Jumping between goals

\*: (more like _is sort of working_, but everything is still experimental...)

### In Progress
- Code quality improvements

### Planned
- Inline case split

## Thanks to
- [u/algebrartist](https://www.reddit.com/r/agda/comments/qamibt/comment/hhm6jke) for help with the development on reddit and testing
- [banacorn](https://github.com/banacorn/agda-mode-vscode) for agda-mode-vscode and the description of the communication protocol
- [jliptrap](https://github.com/jliptrap) for doing initial testing and reporting issues
