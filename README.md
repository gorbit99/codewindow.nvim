# Codewindow.nvim

Codewindow.nvim is a minimap plugin for neovim, that is closely integrated with treesitter and the builtin LSP to display more information to the user.

![Codewindow in action](https://i.imgur.com/MokAFG0.png)

## How it works

Opening the minimap creates a floating window that will follow the active window around, always staying on the right, filling the entire height of said window.

In this floating window you can see the text rendered out using braille characters. Unless disabled, it will also try to get the treesitter highlights from the active buffer and apply them to the minimap[^1]. If the builtin LSP reports an error
or a warning, it will also appear as a small red or yellow dot next to the line the issue is in. The current viewport is shown as 2 white lines around the block of code being observed.

The minimap updates every time you leave insert mode, change the text in normal mode or the builtin LSP reports new diagnostics.

You can also focus the minimap, this lets you quickly move through the code to get to a specific point.

[^1]: Because one character in the minimap represents several in the actual buffer, it will show the highlights that occured the most in that region.

## Installation

Packer:
```lua
use {
  'gorbit99/codewindow.nvim',
  config = function()
    local codewindow = require('codewindow')
    codewindow.setup()
    codewindow.apply_default_keybinds()
  end,
}
```

## Configuration

The setup method accepts an optional table as an argument with the following options (with the defaults):
```lua
{
  active_in_terminals = false, -- Should the minimap activate for terminal buffers
  auto_enable = false, -- Automatically open the minimap when entering a (non-excluded) buffer (accepts a table of filetypes)
  exclude_filetypes = { 'help' }, -- Choose certain filetypes to not show minimap on
  max_minimap_height = nil, -- The maximum height the minimap can take (including borders)
  max_lines = nil, -- If auto_enable is true, don't open the minimap for buffers which have more than this many lines.
  minimap_width = 20, -- The width of the text part of the minimap
  use_lsp = true, -- Use the builtin LSP to show errors and warnings
  use_treesitter = true, -- Use nvim-treesitter to highlight the code
  use_git = true, -- Show small dots to indicate git additions and deletions
  width_multiplier = 4, -- How many characters one dot represents
  z_index = 1, -- The z-index the floating window will be on
  show_cursor = true, -- Show the cursor position in the minimap
  screen_bounds = 'lines', -- How the visible area is displayed, "lines": lines above and below, "background": background color
  window_border = 'single', -- The border style of the floating window (accepts all usual options)
  relative = 'win', -- What will be the minimap be placed relative to, "win": the current window, "editor": the entire editor
  events = { 'TextChanged', 'InsertLeave', 'DiagnosticChanged', 'FileWritePost' } -- Events that update the code window
}
```
config changes get merged in with defaults, so defining every config option is unnecessary (and probably error prone).

The default keybindings are as follows:
```
<leader>mo - open the minimap
<leader>mc - close the minimap
<leader>mf - focus/unfocus the minimap
<leader>mm - toggle the minimap
```

To create your own keybindings, you can use the functions:
```lua
codewindow.open_minimap()
codewindow.close_minimap()
codewindow.toggle_minimap()
codewindow.toggle_focus()
```

To change how the minimap looks, you can define the following highlight groups 
somewhere in your config:
```lua
CodewindowBorder -- the border highlight
CodewindowBackground -- the background highlight
CodewindowWarn -- the color of the warning dots
CodewindowError -- the color of the error dots
CodewindowAddition -- the color of the addition git sign
CodewindowDeletion -- the color of the deletion git sign
CodewindowUnderline -- the color of the underlines on the minimap
CodewindowBoundsBackground -- the color of the background on the minimap

-- Example
vim.api.nvim_set_hl(0, 'CodewindowBorder', {fg = '#ffff00'})
```

## Working alongside other plugins

I'll try to make sure, that most plugins can be made to work without any issues alongside codewindow. If you find a usecase that should be supported, but can't be, then open an issue detailing the plugin used and the issue at hand.

For the most part most plugins can simply be made to work by making them ignore the Codewindow filetype.

## Performance

I tested the performance on the `lua/codewindow/highlight.lua` file in the repository, which was at the time of testing 179 lines long. Updating the minimap took 7.7ms on average.

## Related projects

- [https://github.com/wfxr/minimap.vim](https://github.com/wfxr/minimap.vim) - A very fast minimap plugin for neovim, though it relies on a separate program
- [https://github.com/echasnovski/mini.nvim](https://github.com/echasnovski/mini.nvim) - Funnily enough, this came out only a couple of days after I started working on codewindow

## TODO

- Help pages for the functions
- Faster updates - theoretically only the lines that were edited need updating
- Git support - I have a free column on the right reserved for it
- More display options - like floating to the left, not full height, etc. etc.
- Code cleanup - I'm putting this on the bottom, because I know I won't get to it
