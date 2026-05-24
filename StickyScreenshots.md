# Context Summary
*Date: 2026-05-23*
*Project: StickyScreenshots — AHK v2 persistent screenshot overlay tool*

## Goal
Replace ShareX's non-persistent sticky note feature with an AHK v2 script that pins screenshot images as borderless always-on-top windows, surviving reboots and persisting position, size, and opacity per image.

## Files

- `StickyScreenshots.ahk` — single-file AHK v2 script, all logic self-contained (~300 lines)
- `%APPDATA%\StickyScreenshots\images.txt` — newline-separated list of pinned image paths
- `%APPDATA%\StickyScreenshots\positions.ini` — per-image window position/size in physical pixels, keyed by path with `\` replaced by `/`
- `%APPDATA%\StickyScreenshots\opacity.ini` — per-image opacity (20–255), keyed by path

## Key Decisions

**No manager UI — file dialog only.**
Originally built a listbox manager with add/remove/reorder. Removed entirely. Workflow is now: file dialog → select (multi-select supported) → spawn. Individual stickies closed by double-click. Manager added friction with no remaining benefit once double-click-to-close existed.

**Physical pixels for all persistence and Win32 calls; logical pixels only for AHK control API.**
Rejected: mixing `g.GetPos`/`WinGetPos` throughout — causes DPI drift on reload. `GetWindowRect`, `GetClientRect`, `GetCursorPos`, `SetWindowPos`, `MoveWindow` all deal in physical. `pic.Move`, `g.Show` take logical. `FillPic` is the single conversion point using `PhysToLog()`.

**`WindowFromPoint` + `GetParent` walk for cursor hit-testing.**
Rejected: coordinate comparison (`GetCursorPos` vs `WinGetPos`) — caused wrong-window zoom when multiple stickies present due to DPI mismatch between mouse and window coords.

**`MakeSizeHandler(meta)` factory function per sticky.**
Rejected: inline lambda closures in the `for` loop — AHK v2 captures loop variables by reference, so all closures shared the last iteration's `meta`, causing all stickies to resize together.

**`SetLayeredWindowAttributes` with `LWA_COLORKEY | LWA_ALPHA` (`0x3`) for both transparency color and opacity in one call.**
Rejected: `WinSetTransColor` + `WinSetTransparent` separately — they share `WS_EX_LAYERED` and conflict when called sequentially.

**Transparency color: magenta `0xFF00FF`.**
Rejected: black `000000` (appears in images), near-white `FEFEFE` (appears in screenshots, caused color inversion artifact).

**Double-click to close sticky; no close button.**
Rejected: overlay close button as separate `+AlwaysOnTop` Gui (appeared over other windows inconsistently), `Button` control inside sticky (showed inconsistently, broke drag), DC drawing (overwritten by picture control repaint).

**Image dimensions measured via hidden probe `Gui` + `pic.GetPos`.**
Rejected: GDI+ `GdipGetImageWidth/Height` — returned 0 on this system silently.

**`SS_REALSIZECONTROL` (`+0x40`) on `AddPicture` for stretching.**
Rejected: `w-1 h-1` (AHK v1 syntax, invalid in v2), `SS_REALSIZEIMAGE` — showed nothing.

**All hotkeys wrapped in `#HotIf StickyUnderCursor()`** — not global. `Win+H` and `Win+J` remain global by design.

**`Ctrl+O` adds more images** (does not replace existing stickies). Existing stickies are destroyed and respawned with the combined list so saved positions restore correctly.

**`DeleteSavedState` cleans both INI files on double-click close.**

## Current State

**Working and confirmed:**
- Borderless always-on-top sticky windows
- Drag to move via `WM_NCLBUTTONDOWN`
- Corner-drag resize; image stretches to fill after 150ms debounce
- `Ctrl+Up/Down` zoom in physical pixels, image fills correctly ✓
- `Ctrl+Left/Right` opacity (20–255, persisted)
- `Win+H` toggle all visibility
- `Win+J` reload script
- `Ctrl+O` over any sticky opens multi-select file dialog; new images added and all respawned
- Double-click to close and remove from list + INI cleanup
- Position/size/opacity persisted across reloads in physical pixels
- Multi-monitor support via physical coordinate storage
- Auto-opens file dialog on launch if image list empty
- DPI-safe: `PhysToLog`/`LogToPhys` conversion only at AHK control boundary

**Known limitation:**
- If second monitor disconnected at launch, Windows moves its windows to primary. Reconnecting doesn't restore them — user must `Ctrl+O` and re-apply.

## Open Questions / Next Steps

- Multi-file select adds all files but doesn't deduplicate — same image can be added twice
- No opacity indicator when adjusting (no visual feedback of current level)
- Z-order not persisted (stickies always spawn in images.txt order)

## Important Constraints & Preferences

- AHK v2 only
- "Keep it terse and professional. If something won't work, say so directly."
- Hotkeys must not be global unless explicitly requested
- No external dependencies, no installer, no background service
- Single `.ahk` file; data files in `%APPDATA%\StickyScreenshots\`
- User display scaling: 150% (confirmed via debug: mouse logical 208,190 vs window physical 1712,552)
- `g.GetPos` returns physical pixels on this system — do not use for coordinate math

## Gotchas

**`g.GetPos` returns physical pixels on this system despite being an AHK logical API.** Do not use for coordinate math. Use `GetWindowRect` + `PhysToLog`.

**`WM_MOUSEMOVE` fires on the picture control child hwnd, not the parent window hwnd.** Hit-testing via `WindowFromPoint` + `GetParent` walk handles this correctly. Do not try to match only `meta.hwnd`.

**AHK v2 fat-arrow lambdas cannot contain braced multi-statement blocks.** Use named functions or comma-chained single expressions.

**AHK v2 `for` loop closures capture variables by reference.** All stickies end up sharing last iteration's values. Always use a factory function (`MakeSizeHandler(meta)`) when binding per-sticky state.

**`GdipGetImageWidth/Height` returned 0 on this system.** Use probe Gui instead.

**`g.Show "w-1 h-1"` is not auto-size in AHK v2.** Must explicitly size the control.

**`WinSetTransColor` and `WinSetTransparent` conflict** — both set `WS_EX_LAYERED`, last call wins. Use `SetLayeredWindowAttributes` with flag `0x3` in one call.

**Size event `w,h` parameters are logical.** After a physical resize via `MoveWindow`/`SetWindowPos`, the Size event fires with logical dimensions that don't directly correspond to the physical client area. `FillPic` ignores `w,h` and re-reads `GetClientRect` to get the true physical client size, then converts with `PhysToLog`.

**`SetProcessDpiAwarenessContext` called from script body has no effect** — AHK sets DPI mode at process startup. Do not add it.

**`#HotIf` conditions must not block** — no `MsgBox` inside `StickyUnderCursor`. Blocks hotkey evaluation thread, hotkeys stop firing.

**`WindowFromPoint` takes a packed `Int64`** (`x | (y << 32)`), not two separate arguments.

**`BrowsePath` destroys and respawns all existing stickies** after adding new ones, so saved positions restore. Do not skip the destroy/respawn step when adding images.

## Intentional Divergences

**`WinSetExStyle("+0x80000", g.Hwnd)` before `SetLayeredWindowAttributes`.**
Sets `WS_EX_LAYERED` manually because `WinSetTransColor` was removed. Without it, `SetLayeredWindowAttributes` silently fails. Removable only if AHK gains a combined color-key+alpha API.

**150ms debounce timer in `FillPic` for `pic.Value` reload.**
`pic.Move` resizes the control but image content doesn't re-render until `Value` is reassigned. Timer fires after resize ends to avoid per-event flicker. Do not remove.

**`MoveWinPhys` uses `SetWindowPos` flag `0x0014` (`SWP_NOACTIVATE | SWP_NOZORDER`).**
Prevents focus steal and z-order disruption on reposition. Magic-number appearance is intentional.

**`loop 5` in `StickyUnderCursor` walking parent chain.**
Safety bound — picture control is one level deep, five iterations is more than enough. Not a meaningful number, just a ceiling.

**200ms timer in `MakeSizeHandler` before `SaveWinPos`.**
Debounces position save during continuous resize drag. Do not collapse into the 150ms image reload timer — they serve different purposes and the save should happen after the reload.