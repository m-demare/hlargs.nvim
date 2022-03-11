# hlargs.nvim

Highlight arguments' definitions and usages, asynchronously, using Treesitter


## Preview

| Before | After |
| --- | ----------- |
| ![before](https://user-images.githubusercontent.com/34817965/153656813-8c037f48-70a8-486d-890a-484695b33067.png) | ![after](https://user-images.githubusercontent.com/34817965/153656820-65bc6144-c4e7-4b5c-a671-0ada8cd8c0eb.png) |


## Installation
This plugin is for [neovim](https://neovim.io/) only (tested on 0.6.1, no idea whether it works on
previous versions or not)

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
  hl_priority = 10000,
  performance = {
    parse_delay = 1,
    slow_parse_delay = 50,
    max_iterations = 400,
    max_concurrent_partial_parses = 30,
    debounce = {
      partial_parse = 3,
      partial_insert_mode = 100,
      total_parse = 700,
      slow_parse = 5000
    }
  }
}
-- (You may omit the settings whose defaults you're ok with)
```

To understand the performance settings see [performance](#performance). The other settings should be
self explainatory

After setup, the plugin will be enabled. You can enable/disable/toggle it using:
```lua
require('hlargs').enable()
require('hlargs').disable()
require('hlargs').toggle()
```

Note: If you want to change the color dynamically, you can do that using the highlight group `Hlargs`

## Supported languages
Currently these languages are supported
- cpp
- java
- javascript
- jsx (react)
- lua
- php
- python
- tsx (react)
- typescript
- zig

Note that you have to install each language's parser using `:TSInstall {lang}`

### Request new language
Please include a sample file with your request, that covers most of the edge cases that specific
language allows for (nested functions, lambda functions, member functions, parameter destructuring,
etc). See [examples](https://github.com/m-demare/hlargs.nvim/tree/main/testfiles).

Also do note that I can't support a language that doesn't have a Treesitter parser implemented.
Check [here](https://github.com/nvim-treesitter/nvim-treesitter#supported-languages)


## Performance
This plugin uses a combination of incremental and total parsing, to achieve both great speed and
consistent highlighting results. It works as follows:
- When a new buffer is opened, or when a file is externally modified, a total parse task is
  launched. This is CPU intensive, but should rarely happen
- When the buffer is modified, a partial task is launched for every modified group of lines
  (identifying the region that should be parsed depending on what was modified), up to
  `max_concurrent_partial_parses`. If this is exceeded (e.g. by a big find and replace), a total
  parse task is launched. Partial tasks are extremely fast/lightweight, allowing for real time
  highlighting with barely any CPU impact. However, it is not 100% precise, in some weird edge cases
  it might miss some usages. Hence, upon every change, with a big debouncing, a "slow" task is
  launched
- Slow tasks are the same as total tasks, except they are throttled on purpose so that they use
  basically 0 CPU. The idea is that partial tasks are generally very precise, so these just run in
  the background when needed to fix some of the small imprecisions that might be left

The results of these 3 types of tasks are merged in order to always show the most up to date
information

There are a couple of settings that let you adjust performance to your own use case. I recommend
only playing with them if you are having some specific issue, otherwise the defaults should work
fine
- `parse_delay` is the time between parsing iterations, left for vim to compute other events. Longer
  means less CPU load, but slower parsing (default: 1ms)
- `slow_parse_delay ` is the same as `parse_delay`, but for slow tasks. I should be set in a value
  such that CPU usage from slow parses is negligible (default: 50ms)
- `max_iterations` is the maximum amount of functions it will parse. The main objective of this is
  that it doesn't waste too much time parsing huge minified files, but you can set it lower if your
  PC struggles with smaller files (default: 400)
- `max_concurrent_partial_parses` is the maximum amount of partial parsing tasks allowed. If the
  limit is exceeded, no more partial tasks will launch, and instead a single total task will be used
  (default: 30)
- `debounce.partial_parse`: the time it waits for new changes before launching the partial tasks for
  some changes. The idea is that when multiple changes happen in a short amount of time, overlapping
  changes can be merged into a single task (default: 3ms)
- `debounce.partial_insert_mode`: same as previous, but for insert mode. If you don't want real time
  highlighting in insert mode, you can increase this to 1-2 seconds (default: 100ms)
- `debounce.total_parse`: same but for total parses. Rarely used. (default: 700ms)
- `debounce.slow_parse`: same but for slow parses. It affects how quickly the highlighting will
  regain consistency after it is lost, but you shouldn't set it too low, it might have a big impact
  (default: 5000ms)

