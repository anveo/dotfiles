-- Godot 4: LSP over the editor's TCP server, DAP debugging, scene tree,
-- run commands, and in-editor docs. Requires Godot's "Enable TCP LSP server"
-- (Editor Settings > Network > Language Server) and the editor to be open.

local godot_filetypes = { "gdscript", "gdshader", "gdresource" }

-- Run a godotdev.nvim run command with console capture forced on or off for
-- this one call. The plugin only exposes a global toggle, so flip it around
-- the call. Caveat: if :GodotRunCurrentScene has to open a Telescope picker
-- (script attached to several scenes), the run happens later and uses the
-- configured default (console on).
local function godot_run(method, console)
  local run_console = require("godotdev.run_console")
  local previous = run_console.opts.enabled
  run_console.opts.enabled = console
  local ok, err = pcall(require("godotdev.run")[method])
  run_console.opts.enabled = previous
  if not ok then
    vim.notify(tostring(err), vim.log.levels.ERROR)
  end
end

-- Buffer-local Godot keymaps under <Leader>G (capital: <Leader>g is git).
local function godot_keymaps(buf)
  local map = function(keys, fn, desc)
    vim.keymap.set("n", keys, fn, { buffer = buf, desc = desc })
  end

  -- Run: lowercase = output in the bottom console, uppercase = detached
  map("<Leader>Gr", function() godot_run("run_project", true) end, "Run project (console)")
  map("<Leader>GR", function() godot_run("run_project", false) end, "Run project (detached)")
  map("<Leader>Gs", function() godot_run("run_current_scene", true) end, "Run current scene (console)")
  map("<Leader>GS", function() godot_run("run_current_scene", false) end, "Run current scene (detached)")
  map("<Leader>Gp", "<cmd>GodotRunScenePicker<CR>", "Pick scene to run")
  map("<Leader>Gc", "<cmd>GodotShowConsole<CR>", "Show run console")

  -- Editor integration
  map("<Leader>Gt", "<cmd>GodotSceneTree<CR>", "Scene tree")
  map("<Leader>Gl", "<cmd>GodotReconnectLSP<CR>", "Reconnect LSP")
  map("<Leader>Gh", "<cmd>GodotToggleInlineHints<CR>", "Toggle inline hints")

  -- Debug (F-keys below are global; these are the leader equivalents)
  map("<Leader>Gd", function() require("dap").continue() end, "Debug: launch / continue")
  map("<Leader>Gb", function() require("dap").toggle_breakpoint() end, "Debug: toggle breakpoint")
  map("<Leader>GB", function()
    require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
  end, "Debug: conditional breakpoint")
  map("<Leader>Gu", function() require("dapui").toggle() end, "Debug: toggle UI")
  map("<Leader>Gx", function() require("dap").terminate() end, "Debug: terminate")

  pcall(function()
    require("which-key").add({ { "<Leader>G", group = "godot", buffer = buf } })
  end)
end

return {
  {
    "Mathijs-Bakker/godotdev.nvim",
    ft = godot_filetypes,
    cmd = {
      "GodotStartEditorServer", "GodotReconnectLSP", "GodotToggleInlineHints",
      "GodotRunProject", "GodotRunCurrentScene", "GodotRunScene", "GodotRunScenePicker",
      "GodotShowConsole", "GodotSceneTree", "GodotSceneTreeRefresh",
      "GodotDocs", "GodotDocsFloat", "GodotDocsBuffer", "GodotDocsBrowser", "GodotDocsCursor",
    },
    dependencies = {
      "mfussenegger/nvim-dap",
      { "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" } },
    },
    opts = {
      -- Formatting is handled by conform (gdstyle), see formatting.lua
      formatter = false,
      -- Plugin's auto_setup uses the legacy nvim-treesitter.configs API, which
      -- doesn't exist on the main branch we use. Parsers live in treesitter.lua.
      treesitter = { auto_setup = false },
      -- Default for :GodotRun* commands; <Leader>GR / <Leader>GS run detached
      run = { console = { enabled = true } },
    },
    config = function(_, opts)
      require("godotdev").setup(opts)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("GodotKeymaps", { clear = true }),
        pattern = godot_filetypes,
        callback = function(event) godot_keymaps(event.buf) end,
      })
      -- The buffer that triggered lazy-loading already fired FileType
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.tbl_contains(godot_filetypes, vim.bo[buf].filetype) then
          godot_keymaps(buf)
        end
      end
    end,
  },

  -- DAP stepping keys are global so they also work with a dap-ui window
  -- focused. Mirrors Godot's own debugger shortcuts (F9 breakpoint, F10 over,
  -- F11 into). Note: F11 is macOS "Show Desktop" if that Mission Control
  -- shortcut is enabled; use <Leader>G maps or arrow keys instead if it fires.
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<F5>", function() require("dap").continue() end, desc = "Debug: launch / continue" },
      { "<F9>", function() require("dap").toggle_breakpoint() end, desc = "Debug: toggle breakpoint" },
      { "<F10>", function() require("dap").step_over() end, desc = "Debug: step over" },
      { "<F11>", function() require("dap").step_into() end, desc = "Debug: step into" },
      { "<F12>", function() require("dap").step_out() end, desc = "Debug: step out" },
    },
  },
}
