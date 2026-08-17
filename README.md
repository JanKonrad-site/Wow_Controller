# WOW Controller

Controller-first UI for **OctoWoW / World of Warcraft 1.12.2**, designed for the **ROG Ally X**. WOW Controller brings the useful parts of a modern console interface to the Vanilla client: a cross-hotbar layout, three modifier layers, controller glyphs, target/interact bindings and an in-game setup guide.

OctoWoW's 1.12 client has no native XInput support. WOW Controller therefore uses two cooperating parts:

- Armoury Crate SE Desktop Mode converts the physical controller to keyboard and mouse input.
- WOW Controller turns that input into a console-style HUD and 24 action slots inside WoW.

No automation, botting, injected DLL or one-button rotation is used. Every action still requires one physical button press.

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
| A / B / X / Y | 1 / 2 / 3 / 4 | Face-button actions |
| D-pad Up / Right / Down / Left | 5 / 6 / 7 / 8 | D-pad actions |
| LB | Shift | Second action layer |
| LT | Ctrl | Third action layer |
| RB | Left mouse button | UI click / select |
| RT | Right mouse button | Camera turn / world interaction |
| L3 | Tab | Next enemy |
| LB + L3 | Shift + Tab | Previous enemy |
| LT + L3 | Ctrl + Tab | Nearest friendly target |
| R3 | Space | Jump |
| View | M | World map |
| Menu | Escape | Back / game menu |
| M1 | F | Interact / right-click target |
| M2 | R | Open or close all bags |

For M1 and M2, disable **Set as Secondary Function** before assigning their own keys.

## First setup in game

1. Run `/octoport setup` to apply and save the recommended bindings.
2. Run `/octoport edit` to display all three layers.
3. Drag abilities onto the base, LB and LT layers with the touchscreen or mouse.
4. Run `/octoport edit` again to return to play mode.

Your previous bindings are backed up per character. Use `/octoport restore` to restore them.

## Commands

- `/octoport` or `/op` — open help.
- `/octoport setup` — back up affected keys and apply the recommended bindings.
- `/octoport restore` — restore the saved bindings.
- `/octoport edit` — show or hide all three action layers.
- `/octoport move` — unlock or lock the HUD for dragging.
- `/octoport scale 0.7-1.6` — change HUD scale.
- `/octoport reset` — reset HUD position and size.
- `/octoport on` / `/octoport off` — enable or disable the controller HUD.

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
