# Blink (iPadOS) — Herdr Navigation Shortcuts

## Prefix Key
- **Ctrl+B** = `0x02` (herdr prefix)
- On Blink: Hold Ctrl, tap B (or use Ctrl+B shortcut if configured)

## Pane Navigation (Hex Sequences for Blink)

| Action | Shortcut | Hex Sequence | Blink Command |
|--------|----------|--------------|---------------|
| **Focus Left** | Prefix + `h` | `0x02 68` | `^B h` |
| **Focus Down** | Prefix + `j` | `0x02 6A` | `^B j` |
| **Focus Up** | Prefix + `k` | `0x02 6B` | `^B k` |
| **Focus Right** | Prefix + `l` | `0x02 6C` | `^B l` |
| **Close Pane** | Prefix + Shift+`W` | `0x02 57` | `^B Shift+W` |
| **Resize Left** | Prefix + Shift+`H` | `0x02 48` | `^B Shift+H` |
| **Resize Down** | Prefix + Shift+`J` | `0x02 4A` | `^B Shift+J` |
| **Resize Up** | Prefix + Shift+`K` | `0x02 4B` | `^B Shift+K` |
| **Resize Right** | Prefix + Shift+`L` | `0x02 4C` | `^B Shift+L` |
| **Split Vertical** | Prefix + `v` | `0x02 76` | `^B v` |
| **Split Horizontal** | Prefix + `-` | `0x02 2D` | `^B -` |

## Tab Navigation

| Action | Shortcut | Hex Sequence | Blink Command |
|--------|----------|--------------|---------------|
| **Next Tab** | Prefix + `n` | `0x02 6E` | `^B n` |
| **Previous Tab** | Prefix + `p` | `0x02 70` | `^B p` |
| **New Tab** | Prefix + `c` | `0x02 63` | `^B c` |
| **Move Tab Right** | Prefix + `.` | `0x02 2E` | `^B .` |
| **Move Tab Left** | Prefix + `,` | `0x02 2C` | `^B ,` |
| **Select Tab 1-9** | Prefix + `1..9` | `0x02 31..39` | `^B 1` (through `^B 9`) |

## Workspace Navigation

| Action | Shortcut | Hex Sequence | Blink Command |
|--------|----------|--------------|---------------|
| **Next Workspace** | Prefix + `)` | `0x02 29` | `^B )` |
| **Previous Workspace** | Prefix + `(` | `0x02 28` | `^B (` |
| **Select Workspace 1-9** | Prefix + Shift+`1..9` | `0x02 21..29` | `^B Shift+1..9` |
| **Rename Workspace** | Prefix + Shift+`S` | `0x02 53` | `^B Shift+S` |
| **New Workspace** | Prefix + `N` (default) | `0x02 4E` | `^B N` |

## Special Actions (Herdr Defaults)

| Action | Shortcut | Hex Sequence |
|--------|----------|--------------|
| **Goto (all workspaces/tabs)** | Prefix + `w` | `0x02 77` |
| **Edit Scrollback** | Prefix + `e` | `0x02 65` |
| **Detach Session** | Prefix + `d` | `0x02 64` |
| **Command Palette** | Prefix + `:` | `0x02 3A` |

---

## How to Use in Blink

### Method 1: Type Directly
1. Hold **Ctrl** and tap **B** (sends `0x02`)
2. Then type the action key (e.g., `h` for left, `j` for down)
3. Example: `Ctrl+B` then `h` = focus left pane

### Method 2: Using Escape Sequences
You can create Blink keyboard shortcuts that send raw hex:
- Go to **Blink Settings** → **Keyboard** → **Add Custom Shortcut**
- Bind to sequence: `\x02h` (focus left)
- Bind to sequence: `\x02j` (focus down)
- etc.

### Method 3: Hex Input
In Blink, some terminals accept hex directly:
- Press sequence: `Ctrl+B` (0x02) + key code
- Example for "focus down": `0x02 0x6A`

---

## Quick Reference Card

```
NAVIGATION (Ctrl+B + key):
  h/j/k/l  = focus left/down/up/right
  
RESIZING (Ctrl+B + Shift + H/J/K/L):
  H/J/K/L  = resize left/down/up/right

TABS (Ctrl+B + key):
  c        = new tab
  n/p      = next/previous tab
  ./,      = move tab right/left
  1-9      = select tab by number

WORKSPACES (Ctrl+B + ...):
  N        = new workspace
  )/( = next/previous workspace
  Shift+1-9 = select workspace

PANES (Ctrl+B + ...):
  v        = split vertical
  -        = split horizontal
  Shift+W  = close pane
  w        = goto tree (all workspaces/tabs)
```

---

## Tips for iPad Usage

1. **Enable Ctrl Key**: In Blink Settings, make sure Ctrl key is visible/enabled
2. **Create Shortcuts**: Use Blink's keyboard settings to create custom shortcuts for frequent actions
3. **Use External Keyboard**: Works best with an external keyboard (Magic Keyboard, etc.)
4. **SSH Friendly**: These are bare herdr chords, work perfectly over SSH from any machine
5. **No macOS CMD**: iPad Blink uses Ctrl, not CMD, so use Ctrl+B instead of the macOS ⌘-based shortcuts
