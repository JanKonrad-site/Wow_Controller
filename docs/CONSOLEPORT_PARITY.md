# ConsolePort parity plan for OctoWoW 1.12

This document treats ConsolePort as the product/UX reference, not as a drop-in
dependency. OctoWoW loads interface `11200`. ConsolePort `master` targets modern
Retail/Classic interfaces and its `legacy` branch targets interface `90000`.
The upstream repository also packages several addons in subdirectories, while
the current OctoLauncher entry expects one addon TOC in the repository root.

## Compatibility decision

| ConsolePort area | 1.12 implementation | Status after 0.6.0 |
|---|---|---|
| Controller setup | Capture keyboard/mouse signals produced by Armoury Crate | Safe session-only setup |
| Character movement | Four left-stick key signals routed to native WoW movement start/stop functions | Implemented; session-only and reversible |
| Action bars | Addon-owned visual mirrors of Blizzard action slots | Safe base implemented |
| Modifier layers | Shift/Ctrl or mapped LB/LT layers | Implemented |
| Targeting | Friendly/enemy cycling through 1.12 targeting API | Implemented; hardware test required |
| Reticle | Addon-owned center overlay with target state | Implemented, opt-in |
| Utility rings | Eight-slot radial menu | Implemented, opt-in |
| Menu navigation | Focus graph for known Blizzard panels | Partial; expand panel by panel |
| UI cursor | Armoury Crate right-stick mouse mapping | External mapping; 1.12 has no native gamepad cursor API |
| World interaction | Target + `TurnOrActionStart/Stop` | Partial; modern interact/gamepad APIs do not exist |
| On-screen keyboard | EditBox-focused custom keyboard | Planned |
| Unit-frame control | Explicit party/raid focus graph | Planned; no global unit-frame hooks |
| Loot control | Controller focus and loot actions | Planned; current cursor placement remains opt-in |
| Quest control | Confirm/back and optional displayed-quest acceptance | Partial, opt-in |
| Device calibration | Per-input diagnostics for emitted keys/mouse | Partial |

## Non-negotiable safety rules

1. Fresh install is inert until explicitly enabled.
2. Normal setup/play never calls `SaveBindings`.
3. Every temporary binding has an exact session backup and restoration path.
4. No replacement of Blizzard global functions.
5. No reparenting or script replacement on Blizzard/unit frames.
6. Features that change gameplay state are separately opt-in.
7. Each compatibility module needs a WoW 1.12 API test and a ROG Ally hardware
   test before it is enabled by default.

## Upstream and licensing

- ConsolePort: <https://github.com/seblindfors/ConsolePort>
- ConsolePort legacy TOC: <https://github.com/seblindfors/ConsolePort/blob/legacy/ConsolePort/ConsolePort.toc>
- ConsolePort license: Artistic License 2.0. Any copied/modified source must
  retain notices, document differences and follow the Modified Version terms.
- TurtleController: <https://github.com/sigboe/TurtleController>
- ShaguController: <https://github.com/shagu/ShaguController>
- ConsoleExperienceClassic: <https://github.com/pepordev/ConsoleExperienceClassic>

TurtleController and ShaguController target interface `11200`, so they are more
useful API/layout references than modern ConsolePort. Their code must still be
audited before reuse; compatibility alone does not guarantee safe binding or UI
behavior.

ConsoleExperienceClassic also targets Vanilla `1.12.1`. Its documented setup
uses Steam Input to translate a physical controller into keyboard and mouse
signals. WOW Controller follows that compatibility principle for movement, but
does not copy its source and does not persistently overwrite the player's WoW
binding set.
