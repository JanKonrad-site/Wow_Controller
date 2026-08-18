# WOW Controller

Controller-first UI for **OctoWoW / World of Warcraft 1.12.2**, designed for the **ROG Ally X**. WOW Controller brings the useful parts of a modern console interface to the Vanilla client: a cross-hotbar layout, directional targeting, three modifier layers, a radial utility menu and context-aware controller buttons.

OctoWoW's 1.12 client has no native XInput support. WOW Controller therefore uses two cooperating parts:

- Armoury Crate SE Desktop Mode converts the physical controller to keyboard and mouse input.
- WOW Controller turns that input into a console-style HUD, 12 face-button actions, D-pad targeting and an editable radial menu inside WoW.

There is no combat rotation, botting, injected DLL or unattended gameplay. Every combat action still requires one physical button press. Optional quest acceptance only acts after the normal quest detail panel is already open.

## Install with OctoLauncher

1. Open **OctoLauncher** and choose the **Addons** tab.
2. Click **Add custom git addon**.
3. Paste the repository URL: `https://github.com/JanKonrad-site/Wow_Controller.git`
4. Wait for the green check mark and click **Install**.
5. Launch OctoWoW and run `/octoport setup`.

The repository name must remain `Wow_Controller`: OctoLauncher clones it directly to `Interface/AddOns/Wow_Controller` and expects `Wow_Controller.toc` in the repository root.

For a manual installation, download the release ZIP and copy its `Wow_Controller` folder to `Interface/AddOns`.

## ROG Ally X mapping

In Armoury Crate SE, add the actual `WoW.exe` to the Game Library, keep **Control Mode = Auto**, open its Game Profile and customize **Desktop Mode**.

| ROG Ally control | Desktop Mode output | WOW Controller action |
|---|---:|---|
| Left stick | W / A / S / D | Move |
| Right stick | Mouse | Cursor / camera |
| A / B / X / Y | F9 / F10 / F11 / F12 | Context action / face-button actions |
| D-pad Up / Down | Up / Down arrows | Previous / next friendly target |
| D-pad Left / Right | Left / Right arrows | Previous / next enemy target |
| LB | Shift | Second action layer |
| LT | Ctrl | Third action layer |
| RB | Left mouse button | UI click / select |
| RT | Right mouse button | Camera turn / world interaction |
| L3 | Tab | Next enemy |
| R3 | Space | Jump |
| Menu | F8 | Tap: game menu; hold: radial menu |
| View | Escape | Back / close UI |
| M1 | F | Interact / right-click target |
| M2 | R | Open or close all bags |

For M1 and M2, disable **Set as Secondary Function** before assigning their own keys.

## First setup in game

1. Run `/octoport setup` to apply and save the recommended bindings.
2. In Armoury Crate, apply the exact mapping above. In particular, **A must not send Enter**, otherwise WoW opens chat before the addon receives the button.
3. Run `/octoport edit` to display all three layers.
4. Drag four abilities onto each of the base, LB and LT layers with the touchscreen or mouse.
5. Run `/octoport edit` again to return to play mode.

Your previous bindings are backed up per character. Use `/octoport restore` to restore them.

## Commands

- `/octoport` or `/op` — open help.
- `/octoport setup` — back up affected keys and apply the recommended bindings.
- `/octoport restore` — restore the saved bindings.
- `/octoport edit` — show or hide all three action layers.
- `/octoport move` — unlock or lock the HUD for dragging.
- `/octoport scale 0.7-1.6` — change HUD scale.
- `/octoport reset` — reset HUD position and size.
- `/octoport wheel` — open the radial-menu editor; left/right click cycles each slot.
- `/octoport wheel reset` — restore the default radial layout.
- `/octoport target on|off` — toggle automatic enemy targeting when no live target exists.
- `/octoport quest on|off` — toggle automatic acceptance of an already displayed quest.
- `/octoport mount NAME` — choose the mount spell or bag item used by the radial menu.
- `/octoport on` / `/octoport off` — enable or disable the controller HUD.

## Controller behavior

- **A** confirms the visible quest/dialog button or uses face action 1.
- **B** cancels/closes a visible panel or uses face action 2.
- **X/Y** use face actions 3/4.
- **D-pad Up/Down** cycles friendly targets; **Left/Right** cycles enemies.
- Hold **Menu**, point with the right stick and release Menu or press A to execute the selected radial action. B cancels it.
- The default wheel contains Map, Quests, Bags, Character, Mount, Chat, Combat Log and Spellbook. Every position is editable in game.
- Auto quest acceptance can be bypassed temporarily by holding **LB/Shift** while opening the quest.

## Compatibility

- Target: OctoWoW / Vanilla client 1.12.x (`## Interface: 11200`).
- Default Blizzard action bars are supported, including bonus/stance/form bars.
- Full UI replacements that replace or heavily reparent the Blizzard action buttons may conflict.
- `pfQuest`, ShaguTweaks and normal quest/database addons should be compatible.

## Development and releases

The addon files intentionally live in the repository root for OctoLauncher compatibility. Tag a commit as `vX.Y.Z`; GitHub Actions creates `Wow_Controller-vX.Y.Z.zip` containing exactly one top-level `Wow_Controller` directory.

## Credits

The UX is inspired by the controller-first ideas popularized by ConsolePort. Vanilla compatibility research was informed by the MIT-licensed ShaguController project. WOW Controller is an independent implementation and contains no ConsolePort source code.

## License

MIT — see [LICENSE](LICENSE).
