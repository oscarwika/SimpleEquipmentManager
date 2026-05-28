# Simple Equipment Manager

Custom equipment sets for **WoW Classic Anniversary** (interface **20504**). A helmet button on the Character panel opens a side panel to save, swap, and track gear sets—similar to retail’s equipment manager, without replacing Blizzard’s UI.

## Features

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

## CurseForge (copy & paste)

**Short description:** Lightweight equipment sets for WoW Classic Anniversary—save, swap, and track gear from the Character panel with one-click equip and equipped checkmarks.

**Full description:**

**Simple Equipment Manager** adds named gear sets to the Character window: a helmet button opens a side panel with Blizzard-style chrome. Create sets from your current gear, pick an icon from a scrollable grid, equip with one click, and see a checkmark when a set is fully worn. Edit updates name, icon, and saved gear together; delete uses a confirmation dialog. Sets persist in `SimpleEquipmentManagerDB`. Items must be in your bags to equip (not pulled from the bank).

**How to use:** Character window → helmet button → **New Set** / left-click to equip / right-click or gear menu to edit or delete.

**Requirements:** WoW Classic Anniversary, interface 20504.

**Tags:** Equipment, Gear, Sets, Character, Classic, Anniversary, TBC, UI, Quality of Life
