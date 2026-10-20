# Protect The President

A Quake 4 single-player mod (IT 266 midterm). You play the President: unarmed, and kept alive by a five-member protection squad you command with four orders.

## Concept

> Hello, and welcome to Protect The President! You, the president, under the crushing weight of war stepped into the fray to complete vital objectives! But you are NOT a soldier, you have men ready to aid and defend you all the way to extraction. You will hit checkpoints to replenish your men as you advance, but try not to treat them like meat shields!

- The President is **unarmed by design**. You never fire a weapon; your squad does the fighting.
- Your job is to direct the squad and stay alive.

## Your squad

| Name | Role | Weapon | Notes |
|---|---|---|---|
| Overwatch | Marksman | Barrett M82A1 | Long-range precision, heavy hits with a tracer; fragile (100 health) |
| Ram | Breacher | Mossberg 590A1 | Close quarters; the tank (200 health) and regenerates health |
| Thunder | Gunner | M249 SAW | Suppressing fire in long bursts from a 200-round belt (150 health) |
| Doc | Medic | AR-15 (M4A1) | Restores your health; leaves any order to heal you when you are low |
| Wrench | Engineer | Mossberg 590A1 | Repairs your armor; also leaves orders to keep you alive |

Aim at a squad member to see their name and weapon.

## Weapons

The mod uses a contemporary weapons theme: all 11 Quake 4 weapons are renamed after real weapons and retuned toward their real rate of fire, magazine size and damage. The stock models and effects are reused, so there are no custom models.

| Weapon | Replaces | Real weapon | In game |
|---|---|---|---|
| M1911 | Blaster | .45 ACP pistol, 7-round magazine, semi-auto | One shot per trigger pull, up to 4 shots/s; unlimited sidearm ammo (stock blaster, no reload) |
| AR-15 | Machinegun | 5.56 mm rifle, 30-round magazine; the M4 version fires 700-950 rounds/min automatic | 800 rounds/min from the hip, semi-auto when zoomed; 30-round magazine |
| Mossberg 590A1 Shotgun | Shotgun | 12-gauge pump, 8+1 shells, 9 pellets of 00 buckshot | 9 pellets per shell, 8-shell tube, about 1 shot/s |
| M249 SAW | Hyperblaster | 5.56 mm light machine gun, 725-850 rounds/min, 200-round belt | 750 rounds/min, 200-round belt |
| M32 MGL | Grenade Launcher | 40 mm six-shot revolver launcher, about 2-3 rounds/s | 6 rounds, 2 rounds/s |
| MP5 | Nailgun | 9 mm submachine gun, 800 rounds/min, 30-round magazine | 800 rounds/min, 30-round magazine |
| RPG-7 Rocket Launcher | Rocket Launcher | Single shot, hand-reloaded, 4-6 rounds/min | One rocket per shot, one every 2 s (shortened for play) |
| Barrett M82A1 | Railgun | .50 BMG semi-auto sniper rifle, 10-round magazine | 10-round magazine, 1 shot/s, 150 damage |
| TASER X26P | Lightning Gun | Electric stun weapon, 5-second cycle, 15-25 ft probe cartridges | Continuous discharge while held, 25 ft range, low damage |
| AT4 | Dark Matter Gun | 84 mm single-shot recoilless launcher (HEAT) | Fires a rocket instead of the dark matter orb; 1 shot every 2 s |
| M2 Flamethrower | Napalm Launcher | About 7 s of fuel, 20-40 m range | 35 bursts at 5/s, 7 s of fire |

**Seeing the weapons:** the President can't fire them, so the theme shows in two places.
- The squad fires their real weapons in combat.
- Every weapon pickup shows its new name. To see one, spawn it from the console and walk over it: for example `spawn weapon_shotgun`. The other names are `weapon_blaster`, `weapon_machinegun`, `weapon_hyperblaster`, `weapon_grenadelauncher`, `weapon_nailgun`, `weapon_rocketlauncher`, `weapon_railgun`, `weapon_lightninggun`, `weapon_dmg` and `weapon_napalmgun`.

**Notes:**
- Damage numbers use Quake 4's scale.
- The MP5 keeps the stock nail damage, because Strogg enemies share that projectile.
- The TASER has its own damage def for the same reason, so the Makron keeps its stock damage.

**Sources** (real-world figures):
- [M1911](https://en.wikipedia.org/wiki/M1911_pistol)
- [M4](https://www.globalsecurity.org/military/systems/ground/m4-specs.htm)
- [Mossberg 590A1](https://en.wikipedia.org/wiki/Mossberg_500)
- [M249](https://www.globalsecurity.org/military/systems/ground/m249-specs.htm)
- [M32 / MGL](https://en.wikipedia.org/wiki/Milkor_MGL)
- [MP5](https://en.wikipedia.org/wiki/Heckler_%26_Koch_MP5)
- [RPG-7](https://www.globalsecurity.org/military/world/russia/rpg-7-specs.htm)
- [Barrett M82](https://man.fas.org/dod-101/sys/land/m82.htm)
- [TASER X26P](https://file.lacounty.gov/SDSInter/bos/supdocs/LASDReponsetoTaserRequest4.7.2023.pdf)
- [AT4](https://en.wikipedia.org/wiki/AT4)
- [M2 flamethrower](https://en.wikipedia.org/wiki/M2_flamethrower)

## Controls

| Key | Order | What the squad does |
|---|---|---|
| **1** | Attack | Runs to the spot you aim at and fights in that zone. Aim at floor they can reach. |
| **2** | Protect | Forms a ring around you that moves with you, and fights from inside it. |
| **3** | Wait | Holds position and still shoots. |
| **4** | Scatter | Spreads into forward fighting positions and fights freely. |
| **Tab** | Help screen | Shows or hides the in-game help. |

- **Every order is a toggle.** Press the same key again and the squad goes back to following you. Pressing a different order switches straight to it.
- **The order panel** in the top-left corner of the HUD lists the four orders and highlights the active one. Nothing is highlighted while the squad is following you.
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
- Loose mod files (`def\`, `def\weapons\`, `guis\`) go in the `ABRACADABRA` folder, where they override the stock pk4s.

## Coming soon

- Mission objectives
- Checkpoints that replenish the squad
- The extraction holdout
