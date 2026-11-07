# readmode.nvim

Centered reading mode for Neovim 0.10+. Soft wrapping, configurable width, and
editable text. Preserves your splits and window settings.

## Install

```lua
vim.pack.add({ "https://github.com/TheOddKn1ght/readmode.nvim" })
```

## Usage

`:Readmode` toggles reading mode. Also accepts `enable` or `disable`.

```lua
require("readmode").setup({ width = 80, padding = 2 }) -- optional
vim.keymap.set("n", "<leader>r", "<cmd>Readmode<cr>", { desc = "Toggle reading mode" })
```

## Tests

```sh
nvim --headless -u NONE -l tests/readmode.lua
```
