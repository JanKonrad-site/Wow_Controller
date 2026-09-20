# WOW Controller

Controller-first UI for **OctoWoW / World of Warcraft 1.12.2**, designed for the **ROG Ally X** and other keyboard/mouse-emulating controllers. Version 0.9.1 fixes live input setup: the left stick and D-pad are captured as eight physical signals in one atomic calibration, settings remain controller-operable while gameplay is off, and the 20-slot editor works independently of controller activation.

OctoWoW's 1.12 client has no native XInput support. Armoury Crate SE or Steam Input must convert the physical controller to keyboard/mouse signals. The addon binds the four left-stick signals directly to Blizzard's native movement commands; it never calls protected movement functions from Lua. LT and RT emit real Shift/Ctrl modifiers, following the layered-key principle used by ConsoleExperienceClassic. WOW Controller keeps every binding temporary and reversible.

## Safety model

- A fresh installation is **OFF** and does not alter Blizzard UI, quests, targets or bindings.
- Updating from 0.1-0.4 removes persisted `OCTOPORT_*` commands and restores the pre-addon bindings captured by those releases.
- Setup stores chosen keys only in `OctoPortConfig`; it does not call `SaveBindings`.
- Enabling the controller applies temporary bindings. Disabling it or logging out restores the exact previous actions, including both original keys of a Blizzard command. A recovery baseline is also stored before each temporary change, so it survives `/reload` and is cleared only after exact restoration.
- Binding changes are never attempted during combat lockdown. The requested state is shown as pending and is reconciled automatically after combat.
- All 20 combat inputs bind to Blizzard's native `ACTIONBUTTON` / `MULTIACTIONBAR` commands. The addon never calls `UseAction` for normal controller combat.
- The HUD mirrors action slots in addon-owned frames. It never reparents Blizzard action buttons and never replaces `ActionButton_GetPagedID` or `UIParent_ManageFramePositions`.
- `/octoport restore` is an explicit emergency cleanup and turns the addon OFF.

There is no combat rotation, botting, injected DLL or unattended combat. Every combat action still requires a physical button press. Optional quest acceptance only acts after the normal quest detail panel is already open.

## Install or update with OctoLauncher

1. Open **OctoLauncher** and choose **Addons**.
2. Add the custom git addon `https://github.com/JanKonrad-site/Wow_Controller.git`.
3. Install or update it, then launch OctoWoW.
4. In ROG Command Center select **Desktop Mode** for OctoWoW. Do not leave it on Auto/Gamepad Mode.
5. On the first 0.5 launch, the addon repairs older saved bindings and remains OFF.
6. Left-click the cyan **WC** button beside the minimap and test the physical controls. Right-click it to open Setup; typing `/wc` is no longer necessary.
7. Choose **KALIBROVAT 8 SMERU** and release each requested direction before the next step. The addon enables gameplay only after it has actually observed eight unique signals.
8. Use **NACIST ABXY 1-4** if the physical face buttons currently emit Enter, Escape or other keys, then press **ZAPNOUT BEZPECNE**.

The repository name must remain `Wow_Controller`: OctoLauncher clones it directly to `Interface/AddOns/Wow_Controller` and expects `Wow_Controller.toc` in the repository root.

## First controller setup

The wizard captures all four left-stick directions, A/B/X/Y, all four D-pad directions, Menu, LT and RT. LT and RT are required and must emit two different native modifiers chosen from Shift, Ctrl and Alt. LB/RB, L3/R3, View and rear M1/M2 are optional. Enter, Escape, arrows, F-keys, ordinary keys and mouse buttons are supported.

Direction calibration is transactional. It first stages all eight real inputs, waits for every direction to be released, rejects a duplicate signal, and commits the new map only after the last valid direction. Cancelling leaves the previous map untouched. A preset is only an expected layout and no longer counts as proof that the physical stick and D-pad are separate. Start calibration outside combat; protected binding changes are deferred until combat ends instead of triggering a Blizzard UI blocked-action warning.

The minimap **WC** button remains visible even while the controller session is off. Left-click opens **RAW TEST**, which displays exactly what WoW receives before the addon binds anything, including `ESCAPE`; right-click opens Setup. Move the left stick first: it should report `W`, `S`, `A`, `D`. If it reports arrow keys, the Armoury Crate profile—not Lua—is routing the stick to the D-pad targeting signals. Right-stick movement is reported as `MOUSE MOVE`.

If at least one physical button reaches the raw test, press it and choose **VSTUP = MENU**. WOW Controller enables a menu-only session and binds only that one key; movement and face-button bindings remain untouched.

The left stick and D-pad must emit eight distinct signals. A common mapping is stick `W/A/S/D` and D-pad arrow keys; ConsoleExperienceClassic-style `5/6/7/8` D-pad signals work as well. Version 0.9.1 verifies the signals through live capture and refuses to enable a partial or duplicate profile. One keyboard signal cannot identify whether it came from the physical stick or D-pad.

If the wizard does not advance when you press a control, that button is not sending a keyboard/mouse signal to WoW. Assign any unused key to it in the game's Armoury Crate Desktop Mode profile, return to WoW and press it again. For mouse-button capture, point the cursor at the capture window. Auto mode can select Gamepad Mode, which the old 1.12 client cannot consume as XInput.

For M1/M2, clear **Set as Secondary Function** in Armoury Crate before assigning an unused keyboard key to each paddle. Confirm those keys in RAW TEST before binding them—the addon cannot detect a paddle that emits no keyboard or mouse event. The physical Command Center and Armoury Crate buttons are system-reserved and cannot be remapped; use View for WOW Controller settings instead.

Recommended device-side controls that do not need the wizard:

| ROG Ally control | Armoury Crate output | Purpose |
|---|---|---|
| Left stick | W / A / S / D | Direct Blizzard movement bindings |
| Right stick | Mouse | Camera, cursor and radial direction |
| LT | Shift | Eight-action LT layer |
| RT | Ctrl | Eight-action RT layer |
| LB | Left mouse button | UI click (device-side) |
| RB | Right mouse button | Camera and world interaction (device-side) |
| L3 | Num Lock | Auto run |
| R3 | Space | Jump |
| Menu | F8 | Radial wheel / game menu |
| View | Any unused key | WOW Controller settings |
| M1 | Any unused key | Configurable; default settings |
| M2 | Any unused key | Configurable; default interact |

The **NACIST ABXY 1-4** Setup button asks for physical A, B, X and Y in sequence, then routes whatever they actually emit to Blizzard's native action slots 1, 2, 3 and 4. This also works when Desktop Mode currently emits Enter or Escape. The original Enter/Escape actions are restored when the controller session is disabled or the player logs out.

The fixed profile—stick W/A/S/D, ABXY 1-4, D-pad arrows, LT Shift, RT Ctrl, Menu F8, View F7 and rear F6/F5—is available through **VYCHOZI PROFIL** or `/octoport preset`. It requires matching Armoury Crate output. All bindings remain temporary.

## Controller menu

Open it by right-clicking the persistent **WC** minimap button, with `/wc`, `/octoport`, or with the smaller WC button on the controller HUD. Left-clicking the minimap button opens raw input testing.

- **SETUP** — full wizard, safe ROG Ally profile, enable/disable and emergency restore.
- **OVLADANI** — view or remap every controller action separately; old assignments may now be swapped instead of blocking capture.
- **HRANI** — auto target, auto quest, configurable M1/M2 actions, 20-slot HUD editor and radial settings.
- **DIAGNOSTIKA** — all controller inputs, native/pass-through state and explicit system-only ASUS buttons; **RAW TEST** displays actual incoming keys and mouse signals.

Settings use their own temporary navigation bindings, so D-pad and A/B remain usable even when the gameplay profile is off or has failed validation. Closing Settings restores the exact previous bindings.

Inside the menu, D-pad left/right changes tabs and up/down moves focus. Use A or LB/left click to activate the highlighted control; B or View closes the menu.

## Default behavior

- D-pad Up/Down cycles friendly targets and Left/Right cycles enemy targets through Blizzard's native target commands. The HUD mirrors the resulting friendly/enemy target change; holding LT or RT temporarily changes all four D-pad directions into action inputs.
- Left stick drives Blizzard's native forward/backward/strafe binding commands. Its four emitted keys are active only during the controller session and are restored exactly when the addon is disabled or the player logs out.
- D-pad controls Controller settings and cardinal radial selection; movement keys remain owned by Blizzard UI to avoid protected-action blocking.
- A/B/X/Y use Blizzard's native action slots 1/2/3/4 through the physical signals captured by Setup.
- LT + ABXY/D-pad uses action slots 61-68; RT + ABXY/D-pad uses slots 49-56. Movement stays on the four base W/A/S/D bindings while either trigger is held. During the session, conflicting SHIFT/CTRL movement chords are cleared so they fall through to W/A/S/D, then restored exactly on disable; the addon never creates third movement aliases that could evict the base keys under Vanilla's two-key-per-command limit.
- Choose **UPRAVIT 20 AKCI** and drag spells or items directly onto the addon's 4 + 8 + 8 slot HUD. The editor is visible and clickable even while controller gameplay is off. Right-click a slot to pick its action up and use **HOTOVO** to close the editor.
- Tap Menu for the game menu. Hold Menu for the eight-slot radial utility wheel.
- In the radial wheel, aim with the mouse/right stick or select cardinal slots with D-pad; releasing Menu activates the selected utility.
- The default wheel contains Map, Quests, Bags, Character, Mount, Chat, Combat Log and Spellbook. Its eight positions are editable.
- Combat actions are never intercepted by Lua. Use D-pad Right for the next enemy or D-pad Left for the previous enemy.
- Auto quest accepts an already displayed quest. Hold LT while the quest opens to read it first.

## Commands

- `/wc`, `/octoport` or `/op` — open Controller settings.
- `/octoport setup` — start the binding wizard.
- `/octoport test` — open raw keyboard/mouse input testing.
- `/octoport preset` — select the session-only universal keyboard/mouse profile.
- `/octoport diagnostics` — open live input testing.
- `/octoport restore` — remove saved `OCTOPORT_*` bindings, restore captured actions and turn the addon off.
- `/octoport edit` — show or hide all 20 editable action slots.
- `/octoport move` — unlock or lock the HUD.
- `/octoport scale 0.7-1.6` — resize the HUD.
- `/octoport wheel` — edit the radial menu.
- `/octoport quest on|off` — toggle quest acceptance.
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
