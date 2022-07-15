# spautocmd.nvim

A small plugin which helps you create autocmds with lua tables.

## How to use

Users will need to call `require` to set the autocmds. This plugin will do
nothing by default.

```lua
require("spautocmd").setup({
	cmds = {
		<filetype> = {
			<action> = {
				<...commands>
				[
					<trigger> = {
						<...commands>
						key = ""
						options = {}
					}
				]
			}
		}
	}
})
```

It looks quite complicated but here is the breakdown:

1. We start by the `cmds` key
2. Then we specify which filetype we want to define the autocmd on,
   For example `lua`
3. After that we specify the action. The action names are the same as the
   autocmd names, like `BufWritePre` etc.
4. Inside the action name, you can list the commands like an array. Note that
   the commands needs to be a string, not a lua function.

Here is an example:

```lua
require("spautocmd").setup({
	cmds = {
		c = {
			BufWrite = {
				":!cmake --build ./build",
				":echo Hello"
			}
		}
	}
})
```

This plugin will automatically create a augroup for it. When you save a C file
the commands are called.

## Triggered augroups

If you place your commands inside the `trigger` key, those commands will not
be registered automatically at startup, but delayed until you start them. Here
is an example:

```lua
require("spautocmd").setup({
	cmds = {
		c = {
			BufWrite = {
				trigger = {
					":!cmake --build ./build",
					":echo Hello",
					key = "<C-o>",
					options = {
						silent = true
					}
				}
			}
		}
	}
})
```

Now, the augroup will only be activated if you hit `<C-o>`.
If you hit `<C-o>`, the augroup will be removed. The `options` are passed
directly to the `vim.keymap.set()` function.
