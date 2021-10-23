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

### In Progress
- Syntax highlighting

### Planned
- Refinement
- Context
- Auto
- etc.
