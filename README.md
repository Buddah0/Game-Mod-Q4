# Protect The President

A Quake 4 single-player mod (IT 266 midterm). You play the President: unarmed, and kept alive by a five-member protection squad you command with four orders.

## Concept

> Hello, and welcome to Protect The President! You, the president, under the crushing weight of war stepped into the fray to complete vital objectives! But you are NOT a soldier, you have men ready to aid and defend you all the way to extraction. You will hit checkpoints to replenish your men as you advance, but try not to treat them like meat shields!

- The President is **unarmed by design**. You never pick up or fire a weapon; your squad does the fighting.
- Your job is to direct the squad and stay alive.

## Your squad

| Name | Role | Notes |
|---|---|---|
| Overwatch | Marksman | Long-range precision; fragile (100 health) |
| Ram | Breacher | Close-quarters shotgun; the tank (200 health) and regenerates health |
| Thunder | Gunner | Suppressing fire in long bursts (150 health) |
| Doc | Medic | Restores your health; leaves any order to heal you when you are low |
| Wrench | Engineer | Repairs your armor (shotgun); also leaves orders to keep you alive |

## Controls

| Key | Order | What the squad does |
|---|---|---|
| **1** | Attack | Runs to the spot you aim at and fights in that zone. Aim at floor they can reach. |
| **2** | Protect | Forms a ring around you that moves with you, and fights from inside it. |
| **3** | Wait | Holds position and still shoots. |
| **4** | Scatter | Spreads into forward fighting positions and fights freely. |
| **Tab** | Help screen | Shows or hides the in-game help. |

- **Every order is a toggle.** Press the same key again and the squad goes back to following you. Pressing a different order switches straight to it.
- **The crosshair is your aim point** for Attack.
- Movement and every other key are the Quake 4 defaults.

## Console commands

Open the console with `~` (or Ctrl+Alt+~).

| Command | What it does |
|---|---|
| `ptp_squad` | Deploys the squad around you; running it again re-deploys a fresh squad |
| `ptp_help` | Shows or hides the help screen, same as Tab |
| `ptp_attack`, `ptp_protect`, `ptp_wait`, `ptp_scatter` | The four orders, same as keys 1-4 |

To try it out: `map game/airdefense1`, then `ptp_squad`.

## Install and launch

1. Put the `ABRACADABRA` folder inside your Quake 4 install folder, next to `q4base`.
2. Launch with `ABRACADABRA\PTP_Launch.bat`, or run `Quake4.exe +set fs_game ABRACADABRA`.

The intro logos are skipped, and the game goes straight to the main menu.

## Notes

- **Keep multiplayer LAN mode off** (`net_LANServer 0`, the default). With it on, starting a map shows Quake 4's CD key prompt, and pressing Cancel on that prompt quits the game.
- Squad members can occasionally snag on props while moving; that is stock Quake 4 AI pathing.

## Building from source

- Build only `game.vcxproj`, Release | Win32, with `-p:BuildProjectReferences=false` so idLib is never rebuilt.
- Package the resulting `Gamex86.dll`, together with `binary.conf`, into `ABRACADABRA\game000.pk4`.
- Loose mod files (`def\`, `guis\`) go in the `ABRACADABRA` folder, where they override the stock pk4s.

## Coming soon

- Mission objectives
- Checkpoints that replenish the squad
- The extraction holdout
