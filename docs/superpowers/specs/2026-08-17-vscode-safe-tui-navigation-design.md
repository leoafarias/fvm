# VS Code-safe TUI navigation design

## Context

FVM's Noir terminal interface uses Noir's built-in `Tab` traversal. VS Code can
enable "Tab moves focus", which consumes the key before the terminal process
receives it. The live smoke test reproduced this behavior: route, list, action,
and quit shortcuts worked while terminal focus was retained, but `Tab` moved
focus into VS Code chrome.

The configuration screen is the only current screen where an essential action,
switching between Global and Project scopes, depends on reaching another focus
node. The other screens expose their complete workflows through arrows, Enter,
Escape, Space, `U`, `I`, and the `1`–`4` route shortcuts.

## Considered approaches

1. **Add screen-local scope shortcuts and stop advertising Tab as essential.**
   Left selects Global and Right selects Project. This is explicit, works
   whether the parent screen or Noir `Select` owns focus, and does not interfere
   with path editing. This is the selected approach.
2. **Add application-wide next/previous focus letters.** This would expose
   Noir's internal focus-wrapper order, make movement visually ambiguous on
   screens with nested `Focus` widgets, and reserve more keys.
3. **Document a VS Code setting only.** This avoids code changes but leaves a
   required configuration action unavailable under a common host setting.

## Interaction design

- On Configuration, Left switches to Global and Right switches to Project.
- The shortcut is inactive while a path `TextInput` is editing, preserving
  normal caret movement.
- A visible `Left/Right scope` hint appears beside the existing toggle, save,
  and back hints.
- The global footer advertises `1–4 screens` and the quit shortcut. It no longer
  implies that every host forwards Tab.
- The guide keeps Tab/Shift+Tab as supported focus traversal when the terminal
  host forwards those keys and calls out VS Code's Tab-focus interception.

## Implementation boundaries

The change remains inside `ConfigurationScreen`, the shell footer, and TUI
documentation. It does not alter Noir, VS Code settings, configuration storage,
or the focus tree.

## Verification

- A headless key-dispatch test must fail before implementation and then prove
  Right loads Project and Left loads Global without saving a patch.
- Existing configuration and TUI tests must remain green.
- Analyzer and formatting checks must pass for every changed Dart file.
- The compiled executable must be exercised again in VS Code with Tab-focus
  behavior enabled, confirming Left/Right scope switching and clean `Ctrl+X`
  shutdown while terminal focus remains active.
