
find_globals
============

This script checks your LUA files for accidential global variables.


CLI options
-----------

* `--`: End of options. All remaining CLI arguments are treated as file names,
  even if they begin with a dash.
* `--scan`: Check all `*.lua` files in the current working directory and
  its subdirectories.
* `--allow-stray-globals`: Just report the evidence, don't render a verdict.



Configuration
-------------

### Config file locations

find_globals checks these config files (variables explained below):

```text
/etc/lua/find_globals.rc
/etc/lua/find_globals.rc.d/*.rc
$XDG_CONFIG_DIR/lua/find_globals.rc
$XDG_CONFIG_DIR/lua/find_globals.rc
$REPO_TOP/.lua/find_globals.rc
$REPO_TOP/.lua/find_globals.rc.d/*.rc
.lua/find_globals.rc
.lua/find_globals.rc.d/*.rc
```

* If `$XDG_CONFIG_DIR` is unset or empty, it defaults to `$HOME/.config`.
* Entries with `$REPO_TOP` only apply inside git repositories.
  In this case, `$REPO_TOP` points to the top level of the repo's worktree.
* The last pair of entries is relative to the current working directory,
  i.e. where your shell was when it started `find_globals`.

All config files that are an existent regular files are source-d into
the `find_globals` bash script.
You may use them to modify the `CFG` associative array.

* ⚠ __ATTN:__ If several of the paths above happen to coincide,
  your config file will be source-d multiple times.



### Ignore some variable names in one file

To ignore global variables `foo`, `bar`, and `qux`
in one file, just add this line:

```lua
-- lua-find-globals:ignore: foo bar qux
```

* There's also a multi-line format, which may be helpful for using
  alphabetical sorting in semi-simple editors:

  ```lua
  --[[ lua-find-globals:ignore:
      foo
      bar
      qux
      ]]
  ```

* There may be arbitrary whitespace on any side of any name in the list,
  and the outermost whitespace is optional,
  so you could also write the above as any of these:

  ```lua
  --[[lua-find-globals:ignore:foo bar qux]]

      --[[    lua-find-globals:ignore:          foo   bar   qux       ]]

  --[[ lua-find-globals:ignore:    foo

                  bar


          qux


                                    ]]
  ```



### Blindly accept an entire file

The `:ignore:` feature described above supports a magic variable name
`*` (U+002A asterisk). If that is in the list, the file is immediately
considered successfully checked, even if it contains LUA syntax errors.



### Ignore some variable names in an entire git repo

To ignore variables `foo`, `bar`, and `qux` for all files in your git repo:

1.  Create a subdirectory `.lua/find_globals.rc.d/` at the repo top-level.
    (see also: chapter _Config file locations_)
1.  In there, create a file whose name ends with `.rc`
1.  Into that file, write `CFG[ignored_globals]+=' foo bar qux '`

* The `+=` means to add to the defaults.
  Without the `+`, builtins like `tostring` may be contemned.
* The whitespace between the quotes and the names list is there
  to guard the first and last name from being glued to names
  from other config files, or the same config file being source-d
  several times.
* There may be arbitrary whitespace on any side of any name in the list,
  as with the multi-line format of `:ignore:`.



First aid
---------

#### aka "Help, I have too many intentional globals!"

No problem. Here's a nifty trick. Assume your old code is:

```lua
coolModule = { coolNumber = 42, coolFunc = letsHopeThisExists.someFunc }
```

You could transform it to detect missing modules early:

```lua
local function _g(k) return _G[k] or error('Missing global: ' .. k) end
local coolModule = {
  coolNumber = 42,
  coolFunc = _g('letsHopeThisExists').someFunc,
}
_G.coolModule = coolModule
```







-----
