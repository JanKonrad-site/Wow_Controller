# Changelog

## 0.3.0

- Replaced the fixed F-key-only setup with an in-game controller binding wizard that captures the actual keyboard or mouse signal sent by Armoury Crate.
- Added a ConsolePort-inspired Controller menu with Setup, Controls, Gameplay and live Diagnostics tabs.
- Added per-button rebinding, native or custom LB/LT layer support and safe restoration of overwritten bindings.
- Added D-pad navigation in the Controller menu and cardinal D-pad selection in the radial wheel.
- Added a persistent WC settings button to the controller HUD and changed the /wc command to open settings directly.
- Added live input feedback for ABXY, D-pad, Menu, LB and LT so missing device output can be diagnosed in game.
- Kept the legacy F8-F12 ROG Ally preset as an optional fallback.
- Fixed B/back closing visible Blizzard panels instead of accidentally opening the game menu.

## 0.2.0

- Replaced D-pad action slots with directional friendly/enemy targeting.
- Added context-aware A confirm and B back behavior while preserving ABXY actions.
- Added an editable eight-slot radial menu opened by holding Menu/F8.
- Added radial actions for map, quests, bags, character, mount, chat, combat log and spellbook.
- Added optional automatic enemy targeting when no live target exists.
- Added optional automatic acceptance of an already displayed quest, with LB/Shift bypass.
- Moved the ROG Ally X face-button profile to conflict-free F9-F12 keys.
- Fixed action-slot paging for reparented modifier-bar buttons.
- Updated the in-game guide and Armoury Crate mapping.

## 0.1.0

- Initial OctoWoW 1.12.x version.
- Cross-hotbar HUD for eight face/D-pad actions.
- Base, LB/Shift and LT/Ctrl layers (24 action slots).
- Active modifier layer switches automatically.
- Stance, stealth and shapeshift bonus-bar support.
- Loot window placement near the controller-driven cursor.
- Safe, opt-in keybinding setup with per-character restore.
- Edit, move, scale, reset and enable/disable commands.
- ROG Ally X Desktop Mode mapping guide.
- OctoLauncher-compatible Git repository layout.
