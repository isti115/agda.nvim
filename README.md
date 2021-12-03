<div align="center">
  <img src="assets/agda.nvim.png" width="250" />
</div>

# agda.nvim
NeoVim plugin for interacting with Agda written in Lua

_(Note: Sorry for the lack of updates lately, currently I'm waiting for the following issue: https://github.com/agda/agda/issues/5665 to be addressed, but in the meantime I might switch to the Lisp backend, which could be a bit painful in terms of parsing, but at least would enable the further development of this plugin.)_

## Dependencies
- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)

## Installation

### Plug
```
  Plug 'nvim-lua/plenary.nvim'
  Plug 'isti115/agda.nvim'
```

## Usage
By default the usual agda actions are mapped to the conventional keys, preceded by `<LocalLeader>` (`\` by default in NeoVim), such as:
- `\l` - Load
- `\f` - Next goal _(Forward)_
- `\c` - Case split

and so on. See [the source](https://github.com/Isti115/agda.nvim/blob/main/ftplugin/agda.vim) for all available actions!

### Options
| Option        | Possible Values (Defaults in **bold**) |
|---------------|----------------------------------------|
| g:agda_theme  | **dark**, light                        |
| g:agda_keymap | **vim**, emacs, none                   |

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
