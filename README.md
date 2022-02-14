# hlargs.nvim

Highlight arguments' definitions and usages, asynchronously, using Treesitter


## Preview

| Before | After |
| --- | ----------- |
| ![before](https://user-images.githubusercontent.com/34817965/153656813-8c037f48-70a8-486d-890a-484695b33067.png) | ![after](https://user-images.githubusercontent.com/34817965/153656820-65bc6144-c4e7-4b5c-a671-0ada8cd8c0eb.png) |


## Installation
This plugin is for [neovim](https://neovim.io/) only (tested on 0.6.1, no idea whether it works on previous versions or not)

[packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
  'm-demare/hlargs.nvim',
  requires = { 'nvim-treesitter/nvim-treesitter' }
}
```

[vim-plug](https://github.com/junegunn/vim-plug):
```vim
Plug 'nvim-treesitter/nvim-treesitter'
Plug 'm-demare/hlargs.nvim'
```

## Usage

If you are ok with the default settings:
```lua
require('hlargs').setup()
```

To change them
```lua
require('hlargs').setup {
  color = "#ef9062",
  excluded_filetypes = {},
  paint_arg_declarations = true,
  paint_arg_usages = true,
  performance = {
    parse_delay = 1,
    max_iterations = 400
  }
}
```
(You may omit the settings whose defaults you're ok with)

If you want to change the color dynamically, you can do that using the highlight group `Hlargs`

After setup, the plugin will be enabled. You can enable/disable/toggle it using:
```lua
require('hlargs').enable()
require('hlargs').disable()
require('hlargs').toggle()
```

## Supported languages
Currently these languages are supported
- cpp
- java
- javascript
- lua
- python
- typescript
- php

Note that you have to install each language's parser using `:TSInstall {lang}`

### Request new language
Please include a sample file with your request, that covers most of the edge cases that specific language allows for (nested functions, lambda functions, member functions, parameter destructuring, etc). See [examples](https://github.com/m-demare/hlargs.nvim/tree/main/testfiles).

Also do note that I can't support a language that doesn't have a Treesitter parser implemented. Check [here](https://github.com/nvim-treesitter/nvim-treesitter#supported-languages)


## A note on CPU usage
It can get kinda high, especially on larger files. However, parsing is implemented in a non-blocking way, so you shouldn't notice any slowness in the editing. I run a pretty old laptop CPU (i5 5200U), and performance is acceptable up to ~2000 lines files.

There are a couple of settings to adjust performance to your own use case:
- `parse_delay` is the time between parsing iterations, left for vim to compute other events. Longer means less CPU load, but slower parsing (default: 1ms)
- `max_iterations` is the maximum amount of functions it will parse. The main objective of this is that it doesn't waste too much time parsing huge minified files, but you can set it lower if your PC struggles with smaller files (default: 400)

I'll be attempting to keep improving performance, but I'm not sure how much better it can get
