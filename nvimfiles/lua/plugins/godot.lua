return {
  -- Godot 4: LSP over the editor's TCP server, DAP debugging, scene tree,
  -- run commands, and in-editor docs. Requires Godot's "Enable TCP LSP server"
  -- (Editor Settings > Network > Language Server) and the editor to be open.
  {
    "Mathijs-Bakker/godotdev.nvim",
    ft = { "gdscript", "gdshader", "gdresource" },
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
      -- Formatting is handled by conform (gdformat), see formatting.lua
      formatter = false,
      -- Plugin's auto_setup uses the legacy nvim-treesitter.configs API, which
      -- doesn't exist on the main branch we use. Parsers live in treesitter.lua.
      treesitter = { auto_setup = false },
      run = { console = { enabled = true } },
    },
  },
}
