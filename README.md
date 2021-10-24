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
Add your own mappings, for example:
```
nmap <C-c><C-l> :lua require('agda').load()<Return>
nmap <C-c><C-c> :lua require('agda').case()<Return>
```

## Features

### Done
- Goal types
- Version info
- Case splitting
- Context

### In Progress
- Syntax highlighting

### Planned
- Refinement
- Auto
- etc.

## Thanks to
- [u/algebrartist](https://www.reddit.com/r/agda/comments/qamibt/comment/hhm6jke) for help with the development on reddit
- [banacorn](https://github.com/banacorn/agda-mode-vscode) for agda-mode-vscode and the description of the communication protocol
