# Windows 11 Setup Scripts

Run these on a fresh Windows 11 machine to apply quality-of-life tweaks and remove
pre-installed bloat. Double-click the `.bat` launchers — they will trigger a UAC prompt
for admin privileges and then run the corresponding PowerShell script.

## Scripts

### `windows11-setup.ps1` — Registry & UI Tweaks

Run via: **`run-setup.bat`**

| Tweak | Detail |
|---|---|
| Classic context menu | Right-click always shows all options without the "Show more options" step |
| File extensions visible | Explorer shows `.txt`, `.exe`, etc. |
| Hidden files visible | Explorer shows dotfiles and system-hidden files |
| Explorer opens to This PC | Default view is drives, not Quick Access |
| Taskbar cleaned up | Removes Widgets, Task View, and Chat buttons |
| Full path in title bar | Explorer title bar shows the complete folder path |
| Details view as default | All folder types default to Details view for unvisited folders. Folders with saved view state are unaffected — delete `HKCU\...\Explorer\Streams` to reset all per-folder overrides |
| Bing search disabled | Start Menu search stays local; no web results |
| Start Menu recommendations off | Removes suggested/recently added app noise |
| Advertising ID disabled | Decouples app telemetry from a personal ad profile |
| App launch tracking off | Windows stops tracking which apps you open |
| Suggested content off | Removes ads/tips from the Settings app |
| Telemetry minimized | Set to lowest level (requires admin, skipped otherwise) |

A restart of Explorer is triggered automatically at the end. Some Start Menu changes
require a sign-out/sign-in to take full effect.

---

### `windows11-debloat.ps1` — Remove Pre-installed Apps

Run via: **`run-debloat.bat`**

Removes apps via `winget` and `Remove-AppxPackage`. Missing packages are skipped silently.

**Removed:**

| App | Reason |
|---|---|
| Bing Weather / News / Finance / Sports | Redundant with any browser |
| Get Help / Tips | Rarely used help apps |
| Microsoft Solitaire Collection | Game |
| Office Hub | App launcher, not actual Office |
| Mixed Reality Portal | VR launcher |
| People | Contact app with no modern use |
| Skype | Superseded |
| Microsoft To Do | Remove if using another task manager |
| Windows Feedback Hub | Telemetry/feedback UI |
| Windows Maps | Redundant with browser maps |
| Phone Link | Remove if not using Android integration |
| Media Player / Movies & TV | Remove if using VLC or similar |
| Teams (personal) | Consumer Teams — work Teams is unaffected |
| Clipchamp | Video editor |
| Cortana | Voice assistant |

**Kept (commented out):**

| App | Reason |
|---|---|
| OneDrive | In use for shared save game files |
| Xbox packages | Keeping for potential Game Bar use |

To remove a kept package, uncomment its line in `windows11-debloat.ps1` and re-run.

---

## Notes

- `-ExecutionPolicy Bypass` in the `.bat` files is scoped to the launched process only —
  it does not permanently change the system execution policy.
- The debloat script uses `$ErrorActionPreference = 'Continue'` so a missing package
  does not abort the run.
- Both scripts are safe to re-run.
