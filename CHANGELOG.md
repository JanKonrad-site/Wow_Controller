# Changelog

## 0.6.0

- Restored four-direction left-stick movement using the keyboard signals emitted by Armoury Crate or Steam Input.
- Routes stick presses to WoW 1.12 native movement functions and always stops movement on key release.
- Uses the left stick for directional navigation while Controller settings or the radial wheel is open.
- Automatically adds safe `W/A/S/D` movement defaults to existing 0.5 profiles without changing the saved WoW binding set.
- Keeps movement bindings session-only and restores the exact prior W/A/S/D actions on disable or logout.
- Expanded the safety harness to verify movement start, movement stop, zero normal-play persistence and exact restoration.

## 0.5.0

- Added a one-time migration that removes persisted `OCTOPORT_*` commands and restores bindings captured before versions 0.1-0.4 changed them.
- Changed normal setup and play to session-only bindings; `SaveBindings` is now used only by explicit legacy/emergency recovery.
- Added automatic restoration of temporary bindings when the addon is disabled and on `PLAYER_LOGOUT`.
- Removed the global `ActionButton_GetPagedID` and `UIParent_ManageFramePositions` replacements.
- Stopped reparenting or hiding Blizzard action buttons; the controller HUD now uses independent read-only mirror frames.
- Changed fresh-install defaults to OFF, with auto-target, auto-quest and reticle also OFF until explicitly enabled.
- Removed addon ownership of W/A/S/D; left-stick movement stays on the native Armoury Crate keyboard mapping.
- Added static CI safety checks against persistent normal-play bindings and global FrameXML replacement.
- Documented why the current and `legacy` ConsolePort branches cannot run on interface 11200.

## 0.4.0

- Added required left-stick setup for forward, backward and strafe movement using the signals emitted by ROG Ally Desktop Mode.
- Added a centered target reticle with hostile/friendly color, target name, health feedback and adjustable scale.
- Added right-stick mouse-movement detection to live Diagnostics.
- Added optional View, M1 and M2 capture steps; View toggles Controller settings.
- Added configurable rear-paddle actions for settings, interact, jump, autorun, bags, map, targeting, reticle and radial wheel.
- Documented that OctoWoW must use Desktop Mode, how to make M1/M2 standalone, and which ASUS system buttons cannot be remapped.
- Migrated existing 0.3 configurations back through the expanded setup wizard.

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
