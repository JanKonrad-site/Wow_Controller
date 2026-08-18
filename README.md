# WOW Controller

Controller-first UI for **OctoWoW / World of Warcraft 1.12.2**, designed for the **ROG Ally X**. Version 0.3 adds an in-game setup and diagnostics workflow inspired by the strong controller UX principles of ConsolePort while remaining an independent Vanilla implementation.

OctoWoW's 1.12 client has no native XInput support. Armoury Crate SE converts the physical controller to keyboard/mouse signals; WOW Controller now captures those real signals inside WoW instead of assuming fixed F-keys.

There is no combat rotation, botting, injected DLL or unattended combat. Every combat action still requires a physical button press. Optional quest acceptance only acts after the normal quest detail panel is already open.

## Install or update with OctoLauncher

1. Open **OctoLauncher** and choose **Addons**.
2. Add the custom git addon `https://github.com/JanKonrad-site/Wow_Controller.git`.
3. Install or update it, then launch OctoWoW.
4. In game type `/wc` and choose **SPUSTIT PRUVODCE**.
5. Press the requested physical controller button at every step, then verify all green signals in **DIAGNOSTIKA**.

The repository name must remain `Wow_Controller`: OctoLauncher clones it directly to `Interface/AddOns/Wow_Controller` and expects `Wow_Controller.toc` in the repository root.

## First controller setup

The wizard captures A, B, X, Y, all four D-pad directions, Menu, LB and LT. Enter, Escape, arrow keys, F-keys, ordinary keys and mouse buttons are supported.

If the wizard does not advance when you press a control, that button is not sending a keyboard/mouse signal to WoW. Assign any unused key to it in the game's Armoury Crate Desktop Mode profile, return to WoW and press it again. For mouse-button capture, point the cursor at the capture window.

Recommended device-side controls that do not need the wizard:

| ROG Ally control | Armoury Crate output | Purpose |
|---|---|---|
| Left stick | W / A / S / D | Movement |
| Right stick | Mouse | Camera, cursor and radial direction |
| RB | Left mouse button | UI click |
| RT | Right mouse button | Camera and world interaction |
| R3 | Space | Jump |
| View | Escape | Emergency close/back |
| M1 | F | Interact |
| M2 | R | Bags |

The old ABXY F9-F12, D-pad arrows and Menu F8 profile remains available through **F8-F12 PRESET** or `/octoport preset`, but the capture wizard is the recommended setup.

## Controller menu

Open it with `/wc`, `/octoport` or the **WC** button on the controller HUD.

- **SETUP** — full wizard, legacy preset and binding restore.
- **OVLADANI** — view or remap every controller action separately.
- **HRANI** — auto target, auto quest, HUD, bar editor, HUD position/scale and radial settings.
- **DIAGNOSTIKA** — live green signal for every mapped controller input.

Inside the menu, D-pad left/right changes tabs, up/down moves focus, A activates and B closes.

## Default behavior

- D-pad Up/Down cycles friendly targets; Left/Right cycles enemy targets.
- A confirms visible dialogs or uses face action 1. B closes/cancels or uses face action 2. X/Y use face actions 3/4.
- LB and LT select the second and third four-action layers. They can be native Shift/Ctrl or ordinary mapped keys.
- Tap Menu for the game menu. Hold Menu for the eight-slot radial utility wheel.
- In the radial wheel, aim with the mouse/right stick or select cardinal slots with D-pad; A confirms and B cancels.
- The default wheel contains Map, Quests, Bags, Character, Mount, Chat, Combat Log and Spellbook. Its eight positions are editable.
- Auto target acquires the nearest enemy only when an action is pressed without a live target.
- Auto quest accepts an already displayed quest. Hold LB while the quest opens to read it first.

## Commands

- `/wc`, `/octoport` or `/op` — open Controller settings.
- `/octoport setup` — start the binding wizard.
- `/octoport preset` — apply the legacy ROG Ally F-key preset.
- `/octoport diagnostics` — open live input testing.
- `/octoport restore` — restore bindings saved before controller setup.
- `/octoport edit` — show or hide all three action layers for drag-and-drop editing.
- `/octoport move` — unlock or lock the HUD.
- `/octoport scale 0.7-1.6` — resize the HUD.
- `/octoport wheel` — edit the radial menu.
- `/octoport target on|off` — toggle automatic targeting.
- `/octoport quest on|off` — toggle quest acceptance.
- `/octoport mount NAME` — set the radial mount spell or bag item.

## Login credentials

WOW Controller never reads or stores a game password. WoW addons load after account login and cannot safely prefill the login screen. A password in Lua or SavedVariables would be plaintext and could be copied or accidentally committed. Credential autofill belongs in a launcher/password manager backed by the operating system credential vault, not in this addon.

## Compatibility and releases

- Target: OctoWoW / Vanilla client 1.12.x (`## Interface: 11200`).
- Default Blizzard action bars are supported, including bonus/stance/form bars.
- Full UI replacements that heavily reparent Blizzard action buttons may conflict.
- The addon lives in the repository root for OctoLauncher git installation.
- Tags named `vX.Y.Z` produce a release ZIP containing one top-level `Wow_Controller` directory.

## Credits and license

The setup flow, unified binding view, controller navigation and radial utilities are inspired by controller-first UX popularized by [ConsolePort](https://github.com/seblindfors/ConsolePort). WOW Controller contains no ConsolePort source code, artwork or assets.

MIT — see [LICENSE](LICENSE).
