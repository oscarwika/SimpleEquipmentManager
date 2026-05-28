# Simple Equipment Manager

Custom equipment sets for **WoW Classic Anniversary**. A helmet button on the Character panel opens a side panel to save, swap, and track gear sets—similar to retail’s equipment manager, without replacing Blizzard’s UI.

## Features

<img width="1097" height="589" alt="image" src="https://github.com/user-attachments/assets/1c64f83d-c00f-484f-8deb-cd4a5f31bbf8" />

- **Character panel** — Helmet button (top-right) toggles an **Equipment Manager** panel docked beside your paper doll; closes when you switch Character tabs or close the frame.
- **Save sets** — **New Set** stores all equipped armor and weapon slots from what you are wearing now.
- **Name & icon** — Name your set and pick an icon from a scrollable macro-icon grid.
- **Equip** — Left-click a set to equip saved items from your bags (bank/missing items are skipped; chat reports issues).
- **Equipped checkmark** — Shown when every saved slot matches your current gear.
- **Edit** — Right-click a row, or hover the gear icon → **Edit**. **Update** saves the name, icon, and gear from your current equipment in one step.
- **Delete** — Gear menu → **Delete**, with confirmation.
- **Sorted list** — Alphabetical order with a scroll bar for many sets.
- **Persistence** — Saved in `SimpleEquipmentManagerDB` (your WoW `WTF` folder).

## Quick start

1. Open **Character** (`C`).
2. Click the **helmet** button.
3. **New Set** → name, icon, **Save**.
4. **Left-click** to equip; **right-click** or the row **gear** icon to edit or delete.

Chat messages use the `SEM:` prefix.

## Install

1. Copy `SimpleEquipmentManager` to `World of Warcraft\_anniversary_\Interface\AddOns\`.
2. Enable **Simple Equipment Manager** on the character select **AddOns** screen.
3. `/reload`, then open Character.

**Requirements:** Classic Anniversary client, interface **20504** (`SimpleEquipmentManager.toc`).

## Files

| File | Purpose |
|------|---------|
| `SimpleEquipmentManager.toc` | Metadata and load order |
| `SimpleEquipmentManager.lua` | UI and set logic |

---

## Releasing (maintainers)

Automated uploads use [BigWigsMods/packager](https://github.com/BigWigsMods/packager) on tag push (`v1.0.0`, `v1.0.1`, …).

**Ship a version**

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions builds the zip, uploads to CurseForge, and attaches it to a GitHub Release. Version in-game comes from the tag via `@project-version@` in the TOC.
