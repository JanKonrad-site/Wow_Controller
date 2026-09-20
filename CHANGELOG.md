# Changelog

## 0.9.1

- Replaced destructive per-step direction remapping with an atomic eight-input calibration that commits only after all physical signals are unique.
- Added key-release gating so a held analog direction cannot repeat into the following wizard step.
- Fixed remapping and swapping keys that were still owned by the previous profile.
- Added live direction verification; presets and migrated defaults no longer masquerade as tested hardware input.
- Added a separate reversible settings-navigation binding scope, keeping D-pad and A/B usable while gameplay is off or invalid.
- Fixed controller navigation in the radial editor while gameplay is OFF and guaranteed exact restoration on every close path.
- Guarded every binding mutation against combat lockdown and deferred the requested state until `PLAYER_REGEN_ENABLED`, preventing protected Blizzard UI action warnings.
- Reconciled deferred layers in deterministic baseline → gameplay → visible-menu order after combat.
- Persisted the pre-addon binding baseline before temporary changes, so a combat `/reload` can recover the exact original keys before any new controller session starts.
- Snapshotted both key slots of every touched source and destination command, so temporary assignments cannot lose an existing secondary binding.
- Guarded radial, dialog and automatic quest actions during combat instead of asking the protected Blizzard UI to execute them.
- Prevented gameplay bindings from being reinstalled underneath the capture and raw-test overlays.
- Fixed login and modal-close failure paths so a rejected binding cannot leave a visible but inactive HUD.
- Made the 20-slot action editor visible, clickable and immediately refreshed while gameplay is disabled.
- Rebuilt the HUD with separate header/content/footer bands, fixed target D-pad geometry and editor row spacing, and added a visible **HOTOVO** editor control.
- Added passive `PLAYER_TARGET_CHANGED` feedback so native D-pad targeting is reflected immediately in the HUD without replacing Blizzard's target commands.
- Removed the last Lua targeting fallback; D-pad gameplay now uses only Blizzard's native `TARGET*` bindings.
- Replaced LT/RT movement aliases—which could exceed Vanilla's two-key-per-command limit and evict W/A/S/D—with reversible clearing of modifier chords so they fall through to base movement and restore exactly on disable.
- Replaced the Lua 5.1-only `string.match` call so RAW TEST runs on the client’s Lua 5.0 runtime.
- Added a real Core + Bindings + Menu integration harness and expanded regressions for invalid-profile recovery, exact restoration, calibration swaps, duplicate signals, held inputs and offline action editing.

## 0.9.0

- Split the left stick and D-pad into a validated eight-signal profile; controller activation now fails safely on a duplicate or missing direction.
- Added 20 native combat inputs: base ABXY, LT + ABXY/D-pad and RT + ABXY/D-pad.
- Preserved movement while either trigger is held by adding native modified movement bindings.
- Rebuilt the HUD as an editable 4 + 8 + 8 action layout with drag/drop and action pickup.
- Added focused eight-direction calibration and visible LT/RT combination diagnostics.
- Changed LT/RT to required native modifiers and moved device-side mouse clicks to LB/RB defaults.
- Temporarily routes ABXY to controller-menu navigation while settings are open, then restores native combat bindings.
- Converted configurable rear-button interaction, jump, autorun, bags, map and target actions to native Blizzard commands instead of protected Lua calls.
- Kept all runtime bindings session-only with exact restoration and no normal-play `SaveBindings` call.

## 0.8.0

- Removed the CHOD/CIL mode switch; the left stick and D-pad now stay active simultaneously through distinct device signals.
- Migrated the intended ROG Ally layout to left-stick W/A/S/D and D-pad arrow keys, with duplicate-signal detection retained as a hard setup error.
- Added a focused **NACIST ABXY 1-4** wizard that captures the physical A/B/X/Y outputs—including Enter and Escape—and maps them to native Blizzard action slots 1-4.
- Changed the fixed ROG Ally profile from F9-F12 face actions to native keys/actions 1-4.
- Stopped loading the center reticle and removed its controls and M1/M2 action from the active UI.
- Preserved session-only bindings and exact restoration of every overwritten key.

## 0.7.2

- Replaced the one-way arrow emergency profile with a reversible **CHOD/CIL** mode for hardware profiles where the left stick and D-pad emit identical arrow keys.
- Added a persistent minimap mode button: CHOD binds arrows to native movement; CIL binds Up/Down to friendly targeting and Left/Right to enemy targeting.
- Added **VSTUP = CHOD/CIL** to RAW TEST so any working non-arrow button can toggle the mode without opening settings or typing a slash command.
- Added **ABXY = 1 2 3 4**, using Blizzard's native `ACTIONBUTTON1`-`ACTIONBUTTON4` commands with exact session restoration.
- Expanded automated safety and UI tests for mode switching, raw-button assignment, native ABXY actions and restoration.

## 0.7.1

- Fixed raw testing so `Escape` is displayed instead of closing the test, allowing the default Desktop Mode B/Menu signal to be diagnosed.
- Added **POSLEDNI VSTUP = MENU**, which turns any working raw key into a safe session-only settings key.
- Added a menu-only safety mode that activates no movement, targeting or face-button bindings.
- Added **CHUZE ZE SIPEK** for devices whose left stick currently emits arrow keys: arrows bind to native movement, `Escape` opens settings and D-pad targeting is disabled to prevent collisions.
- Added automated restoration tests for both fallback modes.

## 0.7.0

- Added an always-visible `WC` minimap button: left-click opens raw controller testing and right-click opens Setup, even while the addon is disabled.
- Added a raw keyboard/mouse test overlay that identifies the exact signal emitted by every ROG Ally control before any session binding is enabled.
- Added explicit stick-vs-D-pad collision detection so duplicate arrow signals can no longer silently replace native movement with targeting.
- Added RB, RT, L3 and R3 to setup, manual mapping and Diagnostics; RB/RT remain native mouse pass-through controls, while L3/R3 use Blizzard's native auto-run/jump commands.
- Expanded Diagnostics to cover Menu, View, M1/M2, right-stick mouse movement and the system-reserved Command Center/Armoury Crate buttons.
- Enlarged the controller configuration window for the ROG Ally's 720p display while fitting the complete input list.

## 0.6.1

- Fixed the OctoWoW "action only available to the Blizzard UI" error when moving.
- Removed all addon calls to protected movement start/stop functions.
- Left-stick keys now bind directly to Blizzard's native `MOVEFORWARD`, `MOVEBACKWARD`, `STRAFELEFT` and `STRAFERIGHT` commands.
- Preserved session-only activation and exact restoration of the player's original bindings.
- Added a CI guard that rejects protected movement-function calls in future versions.

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
