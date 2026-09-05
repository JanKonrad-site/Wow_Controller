# WOW Controller

Controller-first UI for **OctoWoW / World of Warcraft 1.12.2**, designed for the **ROG Ally X**. Version 0.5 is a safety rebuild: installation is inert, old persisted `OCTOPORT_*` bindings are repaired once, and controller bindings exist only for the current WoW session.

OctoWoW's 1.12 client has no native XInput support. Armoury Crate SE must convert the physical controller to keyboard/mouse signals. The left stick therefore stays native `W/A/S/D` and the right stick stays a mouse; the addon maps only controller actions such as ABXY, D-pad, Menu, View and rear paddles.

## Safety model

- A fresh installation is **OFF** and does not alter Blizzard UI, quests, targets or bindings.
- Updating from 0.1-0.4 removes persisted `OCTOPORT_*` commands and restores the pre-addon bindings captured by those releases.
- Setup stores chosen keys only in `OctoPortConfig`; it does not call `SaveBindings`.
- Enabling the controller applies temporary in-memory bindings. Disabling it or logging out restores the exact previous actions.
- The HUD mirrors action slots in addon-owned frames. It never reparents Blizzard action buttons and never replaces `ActionButton_GetPagedID` or `UIParent_ManageFramePositions`.
- `/octoport restore` is an explicit emergency cleanup and turns the addon OFF.

There is no combat rotation, botting, injected DLL or unattended combat. Every combat action still requires a physical button press. Optional quest acceptance only acts after the normal quest detail panel is already open.

## Install or update with OctoLauncher

1. Open **OctoLauncher** and choose **Addons**.
2. Add the custom git addon `https://github.com/JanKonrad-site/Wow_Controller.git`.
3. Install or update it, then launch OctoWoW.
4. In ROG Command Center select **Desktop Mode** for OctoWoW. Do not leave it on Auto/Gamepad Mode.
5. On the first 0.5 launch, the addon repairs older saved bindings and remains OFF.
6. Type `/wc`, choose **ROG ALLY PROFIL** or run **SPUSTIT PRUVODCE**, then press **ZAPNOUT BEZPECNE**.
7. Verify the controls in **DIAGNOSTIKA**.

The repository name must remain `Wow_Controller`: OctoLauncher clones it directly to `Interface/AddOns/Wow_Controller` and expects `Wow_Controller.toc` in the repository root.

## First controller setup

The wizard captures A, B, X, Y, all four D-pad directions and Menu. View, LB, LT, rear M1 and rear M2 are optional steps. Enter, Escape, arrow keys, F-keys, ordinary keys and mouse buttons are supported. The left stick is not rebound by the addon: map it to `W/A/S/D` in Armoury Crate. The right stick remains a mouse and has its own live movement test in Diagnostics.

If the wizard does not advance when you press a control, that button is not sending a keyboard/mouse signal to WoW. Assign any unused key to it in the game's Armoury Crate Desktop Mode profile, return to WoW and press it again. For mouse-button capture, point the cursor at the capture window. Auto mode can select Gamepad Mode, which the old 1.12 client cannot consume as XInput.

For M1/M2, clear **Set as Secondary Function** in Armoury Crate before assigning an unused keyboard key to each paddle. The physical Command Center and Armoury Crate buttons are system-reserved and cannot be remapped; use View for WOW Controller settings instead.

Recommended device-side controls that do not need the wizard:

| ROG Ally control | Armoury Crate output | Purpose |
|---|---|---|
| Left stick | W / A / S / D | Movement |
| Right stick | Mouse | Camera, cursor and radial direction |
| RB | Left mouse button | UI click |
| RT | Right mouse button | Camera and world interaction |
| R3 | Space | Jump |
| View | Any unused key | WOW Controller settings |
| M1 | Any unused key | Configurable; default settings |
| M2 | Any unused key | Configurable; default interact |

The ABXY F9-F12, D-pad arrows, Menu F8, View F7 and rear F6/F5 profile is available through **ROG ALLY PROFIL** or `/octoport preset`. These bindings are temporary even when the profile is selected.

## Controller menu

Open it with `/wc`, `/octoport` or the **WC** button on the controller HUD.

- **SETUP** — full wizard, safe ROG Ally profile, enable/disable and emergency restore.
- **OVLADANI** — view or remap every controller action separately.
- **HRANI** — auto target, auto quest, reticle, configurable M1/M2 actions, HUD, bar editor and radial settings.
- **DIAGNOSTIKA** — live green signal for every mapped input plus right-stick mouse movement.

Inside the menu, D-pad left/right changes tabs, up/down moves focus, A activates and B closes.

## Default behavior

- D-pad Up/Down cycles friendly targets; Left/Right cycles enemy targets.
- Left stick drives native `W/A/S/D` movement through the Armoury Crate Desktop Mode profile; the addon never takes ownership of movement keys.
- The center reticle is cyan without a target, red for enemies and green for friendly targets; it also shows target health.
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
- `/octoport preset` — select the session-only ROG Ally F-key profile.
- `/octoport diagnostics` — open live input testing.
- `/octoport restore` — remove saved `OCTOPORT_*` bindings, restore captured actions and turn the addon off.
- `/octoport edit` — show or hide a preview of all three action layers. Abilities remain editable on Blizzard's original bars.
- `/octoport move` — unlock or lock the HUD.
- `/octoport scale 0.7-1.6` — resize the HUD.
- `/octoport wheel` — edit the radial menu.
- `/octoport target on|off` — toggle automatic targeting.
- `/octoport quest on|off` — toggle quest acceptance.
- `/octoport reticle on|off` — show or hide the center reticle.
- `/octoport mount NAME` — set the radial mount spell or bag item.

## Login credentials

WOW Controller never reads or stores a game password. WoW addons load after account login and cannot safely prefill the login screen. A password in Lua or SavedVariables would be plaintext and could be copied or accidentally committed. Credential autofill belongs in a launcher/password manager backed by the operating system credential vault, not in this addon.

## Compatibility and releases

- Target: OctoWoW / Vanilla client 1.12.x (`## Interface: 11200`).
- Default Blizzard action bars are mirrored without changing their parent, scripts or tooltip behavior.
- The current ConsolePort repository cannot be installed as a working OctoWoW addon: its current TOC targets modern clients and even its `legacy` branch targets interface `90000`, while OctoWoW requires `11200`. The repository is also a multi-addon package whose TOCs live in subdirectories, not the single-addon root layout expected by this OctoLauncher entry.
- [TurtleController](https://github.com/sigboe/TurtleController) and [ShaguController](https://github.com/shagu/ShaguController) are genuine 1.12 projects and useful compatibility references, but they are not ConsolePort feature-for-feature ports.
- The addon lives in the repository root for OctoLauncher git installation.
- Tags named `vX.Y.Z` produce a release ZIP containing one top-level `Wow_Controller` directory.

## Credits and license

The setup flow, unified binding view, controller navigation and radial utilities are inspired by controller-first UX popularized by [ConsolePort](https://github.com/seblindfors/ConsolePort). Direct source reuse will happen only where it is technically portable to 1.12 and compliant with ConsolePort's Artistic License 2.0; version 0.5 contains no ConsolePort source code or artwork.

The feature-by-feature compatibility decisions are tracked in [ConsolePort parity plan](docs/CONSOLEPORT_PARITY.md).

MIT — see [LICENSE](LICENSE).
