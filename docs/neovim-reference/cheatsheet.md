# Neovim Cheatsheet

Quick reference for the neovim config. Organized by task, not by plugin.
Leader is `<Space>`.

---

## Navigation

### Flash (motion)

| Key | Mode | Action |
|-----|------|--------|
| `s` | n/x/o | Flash jump -- type chars, pick a label |
| `S` | n/x/o | Flash treesitter -- select treesitter nodes |
| `<Leader>j` | n/x/o | Jump to a line below (labels on line starts) |
| `<Leader>k` | n/x/o | Jump to a line above |

### Telescope (fuzzy finder)

| Key | Action |
|-----|--------|
| `<C-p>` | Find files (respects .gitignore, includes hidden) |
| `<C-f>` | Git files only |
| `<C-b>` | Open buffers (MRU order) |
| `<Leader>f` / `<Leader>ff` | Live grep (ripgrep) |
| `<Leader>F` | Grep word under cursor |
| `<Leader>fr` | Recent files |
| `<Leader>fg` | Git status files |
| `<Leader>fh` | Help tags |
| `<Leader>fd` | Diagnostics |
| `<Leader>ft` | Search TODOs (todo-comments) |
| `<Leader><Tab>` | Browse all keymaps |

Inside Telescope:

| Key | Action |
|-----|--------|
| `<Esc>` | Close picker |
| `<C-j>` / `<C-k>` | Navigate results |
| `<C-q>` | Send results to quickfix list |

### Neo-tree (file explorer)

| Key | Action |
|-----|--------|
| `<Leader>d` | Toggle file tree |
| `<Leader>D` | Reveal current file in tree |
| `<C-v>` | Open in vertical split (inside tree) |
| `<C-x>` | Open in horizontal split (inside tree) |

Note: `s`/`S` are unbound in neo-tree so flash.nvim works there too.

### Treesitter Movement

| Key | Action |
|-----|--------|
| `]f` / `[f` | Next/prev function start |
| `]F` / `[F` | Next/prev function end |
| `]c` / `[c` | Next/prev class start |
| `]C` / `[C` | Next/prev class end |
| `]a` / `[a` | Next/prev parameter |

### Other Navigation

| Key | Action |
|-----|--------|
| `]h` / `[h` | Next/prev git hunk (gitsigns) |
| `]d` / `[d` | Next/prev diagnostic (LSP) |
| `]t` / `[t` | Next/prev TODO comment |
| `]q` / `[q` | Next/prev quickfix entry (unimpaired) |
| `]b` / `[b` | Next/prev buffer (unimpaired) |

---

## Editing

### Surround (vim-surround)

| Key | Action | Example |
|-----|--------|---------|
| `ys{motion}{char}` | Add surround | `ysiw"` -- surround word with `"` |
| `cs{old}{new}` | Change surround | `cs"'` -- change `"` to `'` |
| `ds{char}` | Delete surround | `ds"` -- delete surrounding `"` |
| `S{char}` | Surround selection (visual) | Select text, `S(` |

### Alignment (vim-easy-align)

No `ga` mapping is configured. Use the command directly:

| Command | Example |
|---------|---------|
| `:'<,'>EasyAlign =` | Align selection on `=` |
| `:'<,'>EasyAlign \|` | Align on `\|` (markdown tables) |
| `:'<,'>EasyAlign *\|` | Align on ALL `\|` |

Tip: select lines visually first, then `:EasyAlign`.

### Abolish Coercion (vim-abolish)

Place cursor on a word, then:

| Key | Result | Example |
|-----|--------|---------|
| `crs` | snake_case | `fooBar` -> `foo_bar` |
| `crc` | camelCase | `foo_bar` -> `fooBar` |
| `crm` | MixedCase | `foo_bar` -> `FooBar` |
| `cru` | UPPER_CASE | `fooBar` -> `FOO_BAR` |
| `cr-` | dash-case | `fooBar` -> `foo-bar` |
| `cr.` | dot.case | `fooBar` -> `foo.bar` |

Also provides `:Subvert` for case-aware search/replace.

### Commenting (neovim built-in)

| Key | Action |
|-----|--------|
| `gcc` | Toggle comment on current line |
| `gc{motion}` | Toggle comment on motion (e.g. `gcap` = paragraph) |
| `gc` | Toggle comment on visual selection |

### Treesitter Textobjects

Use with operators (`d`, `c`, `y`, `v`, etc.):

| Textobject | Inner / Outer | What it selects |
|------------|---------------|-----------------|
| `af` / `if` | function | Entire function / function body |
| `ac` / `ic` | class | Entire class / class body |
| `aa` / `ia` | parameter | Parameter with separator / parameter value |
| `al` / `il` | loop | Entire loop / loop body |
| `ab` / `ib` | block | Entire block / block body |
| `ai` / `ii` | conditional | Entire conditional / conditional body |

**Conflict note:** `ai`/`ii` also match vim-indent-object's indent
textobject. Treesitter's conditional mapping wins. Use `:normal vai` to
get treesitter conditional; vim-indent-object's `aI`/`iI` (capital I)
still work for strict indent matching.

### Treesitter Swap

| Key | Action |
|-----|--------|
| `<Leader>a` | Swap parameter with next |
| `<Leader>A` | Swap parameter with previous |

### Other Editing

| Key | Action |
|-----|--------|
| `>` / `<` (visual) | Indent/dedent and keep selection |
| `Y` | Yank to end of line (consistent with `C`, `D`) |
| `gV` | Select last changed/pasted text |
| `<C-j>` (insert) | Jump to end of line |
| `<C-e>` / `<C-a>` (insert) | End / beginning of line (emacs-style) |

---

## LSP

All LSP keymaps are buffer-local -- only active when a language server attaches.

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `gI` | Go to implementation |
| `gD` | Go to declaration |
| `gy` | Type definition |
| `K` | Hover documentation |
| `<Leader>rn` | Rename symbol |
| `<Leader>ca` | Code action |
| `<Leader>e` | Show diagnostic float |
| `[d` / `]d` | Previous / next diagnostic |
| `<Leader>ih` | Toggle inlay hints (if server supports it) |
| `<Leader>bf` | Format buffer (conform.nvim, async) |

### Format on Save

Enabled globally via conform.nvim. Configured formatters:

| Language | Formatter |
|----------|-----------|
| Lua | stylua |
| Python | ruff_format |
| JS/TS/JSON/YAML/Markdown | prettier |
| Go | goimports + gofmt |
| Rust | rustfmt |
| Ruby | rubocop |
| Terraform | terraform_fmt |
| Everything else | trim trailing whitespace |

### Installed Language Servers (Mason)

lua_ls, ruby_lsp, ts_ls, gopls, rust_analyzer, terraformls, bashls,
jsonls, yamlls, dockerls, ruff

---

## Git

### Fugitive

| Command | Action |
|---------|--------|
| `:G` | Git status (interactive staging, like `git add -p`) |
| `:G blame` | Git blame |
| `:G log` | Git log |
| `:GBrowse` | Open file on GitHub (via vim-rhubarb) |

### Gitsigns (hunk operations)

| Key | Action |
|-----|--------|
| `]h` / `[h` | Next / previous hunk |
| `<Leader>hs` | Stage hunk (overrides hlsearch toggle in git buffers) |
| `<Leader>hr` | Reset hunk |
| `<Leader>hS` | Stage entire buffer |
| `<Leader>hR` | Reset entire buffer |
| `<Leader>hu` | Undo stage hunk |
| `<Leader>hp` | Preview hunk |
| `<Leader>hd` | Diff this file |
| `<Leader>hD` | Diff against HEAD~ |
| `<Leader>gb` | Toggle line blame |
| `ih` (textobject) | Select hunk (visual/operator) |

Visual mode: `<Leader>hs` and `<Leader>hr` work on selected lines.

### Diffview

| Key | Action |
|-----|--------|
| `<Leader>gd` | Open diff view (all changes) |
| `<Leader>gh` | File history (current file) |
| `<Leader>gH` | Branch history (all files) |

---

## Completion & Snippets

Completion is powered by nvim-cmp with ghost text preview.

| Key | Context | Action |
|-----|---------|--------|
| `<Tab>` | Menu open | Select next item |
| `<Tab>` | In snippet | Jump to next placeholder |
| `<Tab>` | Otherwise | Insert tab |
| `<S-Tab>` | Menu open | Select previous item |
| `<S-Tab>` | In snippet | Jump to previous placeholder |
| `<CR>` | Menu open | Confirm selection (auto-selects first) |
| `<C-Space>` | Insert | Trigger completion manually |
| `<C-n>` / `<C-p>` | Menu open | Next / previous item |
| `<C-b>` / `<C-f>` | Menu open | Scroll docs up / down |
| `<C-e>` | Menu open | Dismiss completion menu |

### Completion Sources (priority order)

1. LSP suggestions
2. LuaSnip snippets
3. Buffer words (fallback)
4. File paths (fallback)

Command line (`:`) and search (`/`) also have completion.

### Snippets

- **friendly-snippets**: VS Code-style snippets for most languages (loaded automatically)
- **Custom snippets**: snipmate format in `nvimfiles/snippets/`
  - `all.snippets` -- global snippets
  - `ruby.snippets` -- Ruby-specific snippets

---

## Project Navigation & Running Code

### Projectionist (alternate files)

| Command | Action |
|---------|--------|
| `:A` | Toggle between source and test file |
| `:AV` | Same, in a vertical split |
| `:AS` | Same, in a horizontal split |
| `:AT` | Same, in a new tab |

Projectionist also defines `:E` type commands based on project context:

| Command | What it opens |
|---------|---------------|
| `:Esource {name}` | Source file (Ruby `lib/` or TS `src/`) |
| `:Espec {name}` / `:Etest {name}` | Test file |
| `:Eservice {name}` | Rails `app/services/` |
| `:Epolicy {name}` | Rails `app/policies/` |
| `:Ecomponent {name}` | Rails `app/components/` |
| `:Ewizard {name}` | Rails `app/wizards/` |
| `:Elib {name}` | Rails `app/lib/` |

All `:E` commands have `:S`, `:V`, `:T` variants for splits/tabs.

Project type is detected automatically:
- **Rails** (`config/environment.rb`) -- custom directories above + vim-rails standard commands
- **Ruby gem** (`Gemfile` without Rails) -- `lib/` <-> `spec/` or `test/`
- **TypeScript** (`tsconfig.json`) -- `src/` <-> `src/*.test.*` or `src/*.spec.*`
- **JavaScript** (`package.json` without tsconfig) -- same pattern with `.js`

Override per-project with a `.projections.json` at the project root.

### vim-rails (Rails projects)

These work in addition to the projectionist commands above:

| Command | Action |
|---------|--------|
| `:Econtroller {name}` | Edit controller |
| `:Emodel {name}` | Edit model |
| `:Eview {path}` | Edit view |
| `:Emailer {name}` | Edit mailer |
| `:Emigration {name}` | Edit migration |
| `:Eschema` | Edit `db/schema.rb` |
| `:Einitializer {name}` | Edit initializer |
| `:Elocale {name}` | Edit locale |
| `:Rails {command}` | Run a Rails command |
| `:Generate {args}` | Run `rails generate` |

All `:E` commands support tab completion and have `:S`/`:V`/`:T` variants.
`gf` on a symbol jumps to its definition (model name, partial path, etc.).

### Dispatch (async commands)

| Command | Action |
|---------|--------|
| `:Dispatch` | Run `b:dispatch` for the current file (see below) |
| `:Dispatch {cmd}` | Run any command async, results go to quickfix |
| `:Make` | Run `makeprg` async, errors go to quickfix |
| `:Start {cmd}` | Run a long-running process in a new terminal |

Dispatch auto-detects the right command per file:

| File type | Default `:Dispatch` command |
|-----------|-----------------------------|
| `*_spec.rb` | `bundle exec rspec {file}` |
| `*_test.rb` | `bundle exec ruby -Itest {file}` |
| Other `.rb` | `bundle exec ruby {file}` |
| `*.test.ts` / `*.spec.ts` | `npx vitest run {file}` |
| Other `.ts` | `npx tsc --noEmit` |

Projectionist `dispatch` key takes priority when defined.

### Database (vim-dadbod)

| Key / Command | Action |
|---------------|--------|
| `<Leader>db` | Toggle database UI sidebar |
| `:DB {query}` | Run a one-off SQL query |
| `:DB select * from users limit 5` | Example: quick table peek |

#### Using the Database UI

`<Leader>db` opens a sidebar with your database connections. Workflow:

1. **Expand a connection** to browse tables, views, and schemas
2. **Press `<CR>`** on a table to see its contents
3. **Open a new query** -- press `o` on the connection name to create a scratch buffer
4. **Write SQL** -- you get autocompletion against your actual schema (table names,
   columns, functions)
5. **Execute** -- with cursor in the SQL buffer, press `<Leader>S` (dadbod-ui default)
   to run the query; results appear in a split below
6. **Save queries** -- queries are saved to `tmp/dbui/` in the project so you can
   revisit them

Inside the DBUI sidebar:

| Key | Action |
|-----|--------|
| `<CR>` | Open/toggle item |
| `o` | Open new query buffer for connection |
| `R` | Refresh |
| `d` | Delete saved query |
| `r` | Rename saved query |
| `q` | Close DBUI |

Database connections can be configured via:
- `DATABASE_URL` environment variable (used by monicur's `.nvim.lua`)
- `vim.g.db` in project-local `.nvim.lua`
- `:DBUI` add connection interactively
- `g:dbs` table in config for static connections

### Project-Local Config (`.nvim.lua`)

Neovim loads `.nvim.lua` from the project root when `exrc` is enabled (it is).
First time, you'll be prompted to trust the file.

Use this for project-specific settings like database connections, custom
`makeprg`, LSP overrides, or additional projectionist projections.

Example (already set up for monicur):

```lua
local db_url = vim.env.DATABASE_URL
if db_url then
  vim.g.db = db_url
  vim.g.db_ui_save_location = vim.fn.getcwd() .. "/tmp/dbui"
end
```

---

## Custom Commands

| Command | Action |
|---------|--------|
| `:Strip` | Strip trailing whitespace (preserves cursor) |
| `:NotRocket` | Convert Ruby hash rockets to modern style (`:key =>` -> `key:`) |
| `:F {filetype}` | Set buffer filetype (e.g. `:F html`) |
| `:FH` / `:FR` / `:FV` | Quick filetype: haml / ruby / vim |
| `:SudoWrite` | Save file as root |

---

## Custom Keymaps

### Essentials

| Key | Action |
|-----|--------|
| `;` | `:` (command mode without shift) |
| `jj` | `<Esc>` (insert mode) |
| `<Leader>w` | Save file |
| `<Leader><Leader>` | Visual line mode (`V`) |
| `<F1>` | Disabled (no accidental help) |

### Quick Close

| Key | Action |
|-----|--------|
| `QQ` | Close window |
| `QW` | Delete all buffers in tab (`windo bd`) |
| `QA` | Close all |
| `Q!` | Force close |

### Clipboard (system)

| Key | Action |
|-----|--------|
| `<Leader>y` | Yank to system clipboard |
| `<Leader>p` | Paste from system clipboard |
| `<Leader>P` | Paste before from clipboard |
| `<Leader>d` (visual) | Cut to system clipboard |

Note: `clipboard=unnamedplus` is set, so default yank/paste already use
the system clipboard. These `<Leader>` maps are explicit alternatives.

### Marks

`'` and `` ` `` are swapped: `'a` jumps to exact column (normally `` ` ``),
`` `a `` jumps to line start (normally `'`). Same for `g'`/`` g` ``.

### Search

| Key | Action |
|-----|--------|
| `?` | Search backward with `\v` (very magic) |
| `<C-l>` | Clear search highlight + redraw |
| `<CR>` (normal) | Clear search highlight |
| `<Leader>hs` | Toggle hlsearch (overridden by gitsigns in git buffers) |
| `<Leader>fc` | Jump to next merge conflict marker |

### Tabs

| Key | Action |
|-----|--------|
| `<S-Left>` / `<S-Right>` | Previous / next tab |
| `<Leader>tn` / `<Leader>tp` | Next / previous tab |
| `<Leader>te` | Open file in new tab |

### Case Manipulation

| Key | Action |
|-----|--------|
| `<Leader>u` / `<Leader>l` | Uppercase / lowercase word |
| `<Leader>U` / `<Leader>L` | Uppercase / lowercase first char |

### Misc

| Key | Action |
|-----|--------|
| `<C-g>` | Toggle relative line numbers |
| `<Leader>tw` | Toggle word wrap |
| `<Leader>cd` | `lcd` to current buffer's directory |
| `<Leader>s` | Source config |
| `<Leader>vi` | Edit config in new tab |
| `<Leader>fef` | Re-indent entire file (`gg=G`) |
| `<BS>` | Navigate to left tmux/neovim pane |
| `<C-\>` | Toggle terminal (also works inside terminal) |

---

## Neovim Built-ins Worth Knowing

These are neovim features (not plugins) that differ from classic vim.

| Feature | How |
|---------|-----|
| Commenting | `gcc` (line), `gc{motion}` -- built-in since nvim 0.10 |
| Open URL | `gx` -- opens URL under cursor in browser |
| Treesitter folding | `zc`/`zo`/`za` -- folds are treesitter-based (`foldmethod=expr`) |
| Live substitution preview | `:s/foo/bar` shows changes live (`inccommand=split`) |
| `:Inspect` | Show treesitter highlight groups under cursor |
| `:InspectTree` | Show full treesitter parse tree |
| `:checkhealth` | Diagnose missing dependencies, broken providers |
| Inlay hints | `<Leader>ih` to toggle (requires LSP support) |
| Undo file | Persistent undo across sessions (enabled in options) |
| `grepprg` | Set to `rg --vimgrep --smart-case` -- `:grep` uses ripgrep |

---

## Automatic Behaviors

These happen without keybindings:

- **Restore cursor** -- reopening a file returns to last position (except git commits)
- **Format on save** -- conform.nvim formats before write
- **Lint on save** -- nvim-lint runs on write/enter/insert-leave
- **Auto-reload** -- files changed outside vim reload automatically
- **Equalize splits** -- window splits rebalance on terminal resize
- **Treesitter context** -- sticky header shows enclosing function/class (top of screen)
- **Ghost text** -- completion preview appears inline as you type
- **Writing warnings** -- words like "obviously", "simply", "just" are highlighted
- **Line overflow** -- columns 116-120 dim, 120+ turn red
- **Close with `q`** -- help, man, quickfix, lspinfo windows close with `q`
- **Endwise** -- auto-inserts `end` in Ruby, Lua, etc.

---

## Workflow Strategies

Multi-plugin combinations for common tasks.

### Rename a Symbol Across a Codebase

1. `<Leader>rn` -- LSP rename (handles imports and references automatically)
2. If LSP can't reach everything: `<Leader>F` on the word to grep, `<C-q>` to
   send to quickfix, then `:cdo s/old/new/g`

### Surgical Edit in a Distant Function

1. `s` to flash-jump near the target
2. `cif` to change inside function (treesitter textobject)
3. Or: `S` to flash-treesitter-select the exact node, then operate

### Stage Partial Changes (interactive)

1. `]h`/`[h` to navigate hunks
2. `<Leader>hp` to preview what changed
3. `<Leader>hs` to stage just that hunk (or visual-select lines first)
4. `:G` to open fugitive status, review staged vs unstaged

### Review a PR / Explore History

1. `<Leader>gd` to open diffview (all uncommitted changes)
2. `<Leader>gh` to see current file's commit history
3. `<Leader>gH` for full branch history
4. Inside diffview: navigate files with tab, `]x`/`[x` for conflicts

### Find and Fix All TODOs

1. `<Leader>ft` to telescope-search all TODOs/FIXMEs
2. `]t`/`[t` to jump between them in-buffer
3. Fix, then `<Leader>hs` to stage the hunk

### Reorder Function Arguments

1. Place cursor on a parameter
2. `<Leader>a` to swap with next, `<Leader>A` to swap with previous
3. Repeat with `.` (vim-repeat)

### Explore Unfamiliar Code

1. `<C-p>` to find the file
2. `K` on any symbol for hover docs
3. `gd` to jump to definition, `<C-o>` to come back
4. `gr` to see all references
5. `S` (flash treesitter) to visually select and understand structure
6. `<Leader>e` to read any diagnostic warnings

### Quick Alignment (e.g., Hash or Table)

1. Visual-select the lines
2. `:'<,'>EasyAlign *|` for tables, `:'<,'>EasyAlign =` for assignments
3. Or use `:Subvert` (abolish) for case-preserving bulk renames nearby

### Navigate Between Test and Implementation

1. `:A` to toggle between source and test (projectionist)
2. `:AV` to open the alternate in a vertical split (keep both visible)
3. `:Dispatch` to run the test asynchronously -- auto-detects rspec/vitest/jest

### Rails Development Cycle

1. `:Econtroller users` to open the controller
2. `:A` to jump to its spec
3. `:Dispatch` to run the spec
4. Results in quickfix -- `]q`/`[q` to navigate failures
5. `gf` on a model name to jump to it, `<C-o>` to come back

### Explore a Database

1. `<Leader>db` to open DBUI sidebar
2. Browse tables, `<CR>` to preview contents
3. `o` on connection to open a query buffer
4. Write SQL with schema-aware autocompletion
5. `<Leader>S` to run the query
