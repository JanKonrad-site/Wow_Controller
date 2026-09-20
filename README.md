# WOW Controller — native profile

Version **1.0.0** is an intentionally minimal controller setup for OctoWoW / World of Warcraft 1.12.x. It removes the custom HUD, minimap icon, setup window, radial menu, targeting layer, quest automation and all runtime key remapping.

The controller now talks directly to Blizzard's normal movement and action-bar bindings. After a one-time safe cleanup of data left by older releases, the addon is passive: it creates no visible UI and does not intercept controller input.

## Why this design

The Vanilla 1.12 client has no native XInput API. An addon receives only the keyboard or mouse signal produced by Armoury Crate, Steam Input or another mapper. If the left stick and D-pad both emit the same arrow key, Lua cannot determine which physical control produced it. Holding LT appears different only because the mapper adds a modifier to the same base key.

Current ConsolePort can read controllers through modern WoW's `C_GamePad` API, which does not exist in 1.12. ConsoleExperienceClassic likewise relies on external keyboard/mouse mapping. For OctoWoW, distinct device-side keys are therefore the reliable solution.

## ROG Ally / Armoury Crate profile

Use a per-game **Desktop Mode** profile attached to the actual WoW executable launched by OctoLauncher.

| Physical control | Keyboard output | WoW result |
|---|---:|---|
| Left stick up | `W` | Move forward |
| Left stick down | `S` | Move backward |
| Left stick left | `A` | Strafe left after the one-time WoW setting below |
| Left stick right | `D` | Strafe right after the one-time WoW setting below |
| A | `1` | Action button 1 |
| X | `2` | Action button 2 |
| Y | `3` | Action button 3 |
| B | `4` | Action button 4 |
| D-pad Right | `5` | Action button 5 |
| D-pad Left | `6` | Action button 6 |
| D-pad Up | `7` | Action button 7 |
| D-pad Down | `8` | Action button 8 |
| LT | `9` | Action button 9 |
| RT | `0` | Action button 10 |
| Right stick click (R3) | `-` | Action button 11 |
| Left stick click (L3) | `=` | Action button 12 |
| Right stick | Mouse | Camera / cursor |

Useful optional controls are LB = left mouse click, RB = right mouse click,
Menu = `Escape`, View = `M`, M1 = `Space` (jump), and M2 = `Tab` (next enemy).
M1/M2 must first be made standalone in Armoury Crate instead of acting as
secondary-function modifiers.

Slots 10–12 use the keyboard keys `0`, `-` and `=`. Do not enter literal multi-character keys `10`, `11` or `12`, and do not use the numpad variants.

LT and RT are ordinary actions in this profile, not modifiers. D-pad directions are ordinary action slots 5–8, not targeting commands.

### Strafe on A/D

Vanilla normally turns with A/D and strafes with Q/E. To keep the requested W/S/A/D stick layout, open Blizzard's normal **Key Bindings → Movement Keys** once and set:

- Move Forward = `W`
- Move Backward = `S`
- Strafe Left = `A`
- Strafe Right = `D`
- clear A/D from Turn Left and Turn Right

If you do not want to change WoW bindings, map stick-left/stick-right to `Q`/`E` in Armoury Crate instead.

## Install / update

1. Install or update `https://github.com/JanKonrad-site/Wow_Controller.git` through OctoLauncher.
2. Start the game and log into a character **outside combat once**. Version 1.0 restores any exact recovery snapshot from v0.9 and removes persistent `OCTOPORT_*` bindings from older releases.
3. Completely restart WoW.
4. Configure the Armoury profile using the table above.
5. In Blizzard's normal Key Bindings, verify Action Button 1–12 use `1 2 3 4 5 6 7 8 9 0 - =` and set A/D to strafe.

After the migration marker is written, later logins call neither `SetBinding` nor `SaveBindings`. The addon contains no enable mode, controller HUD or setup menu.

## Test before launching WoW

Open Notepad with the same Armoury per-game profile active:

- moving the left stick should type `W/S/A/D`;
- pressing the D-pad should type `5/6/7/8`;
- A/X/Y/B should type `1/2/3/4`.

If stick and D-pad still type the same characters, the correct Armoury profile is not active or is attached only to OctoLauncher rather than the actual game executable. No 1.12 addon can split an identical incoming key afterward.

Here “right/left stick click” means R3/L3. If “kloboucek” was meant as RB/LB
instead, assign `-` and `=` to those two physical buttons; WoW only cares about
the resulting keys.

## Safety bridge

`Cleanup.lua` exists only for upgrading from old WOW Controller versions. It:

- restores a valid `bindingRecoverySnapshot` before doing anything else;
- never mutates bindings in combat and retries after combat;
- preserves corrupt or failed recovery evidence instead of discarding it;
- removes historical `OCTOPORT_*` bindings and saves only when persistent legacy cleanup is actually required;
- becomes completely inert after `basicMigrationVersion = 1` succeeds.

`Bindings.xml` contains inert legacy command names for this bridge release so even old saved bindings remain discoverable and removable. Every handler is a no-op.

## Compatibility references

- [Vanilla FrameXML action-button bindings](https://github.com/satan666/WOW-UI-SOURCE/blob/8033710451d7fba6615fb5e9a4e596e976b46fb8/FrameXML/Bindings.xml#L121-L205)
- [ConsoleExperienceClassic key mapping](https://github.com/pepordev/ConsoleExperienceClassic/blob/main/docs/Keybindings.md)
- [ConsolePort gamepad model using modern `C_GamePad`](https://github.com/seblindfors/ConsolePort/blob/master/ConsolePort/Model/Gamepad/Gamepad.lua)
- [ASUS ROG Ally button remapping and per-game profiles](https://rog.asus.com/articles/guides/how-to-remap-buttons-and-create-custom-game-profiles-on-the-rog-ally/)

## License

MIT — see [LICENSE](LICENSE).
