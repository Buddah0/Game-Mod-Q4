# Protect the President: Next Steps (handoff for the planning chat)

**What this is:** the context pass for the next chat, which will plan and then build these four things. **No code was changed to produce this document.** Research was read-only against the repo, the Quake 4 install, and the stock pk4 data.
**Branch:** `personal_deliverable_2`. Uncommitted on it: `game/gamesys/SysCmds.cpp` (the `ptp_squad` command) and `def/ptp_squad.def` (untracked). The ~50 staged `.vs/` files are IDE noise; leave them alone.

## 0. Guard rails (apply to everything below)
- **NEVER rebuild idlib.** Build `game.vcxproj` only (Release|Win32). `game.vcxproj` has a ProjectReference to idlib, so always pass `-p:BuildProjectReferences=false`; it then links the existing `C:\Users\loren\source\repos\Win32\Release\idLib.lib` (dated 2026-09-26; if that date changes, idlib was rebuilt by mistake).
  ```
  "C:\Program Files\Microsoft Visual Studio\18\Community\MSBuild\Current\Bin\MSBuild.exe" game.vcxproj -p:Configuration=Release -p:Platform=Win32 -p:BuildProjectReferences=false -m -nologo -v:minimal
  ```
- Ignore mpgame. Output is `Win32\Release\Gamex86.dll`. Some SDK headers are extensionless (`#include "TypeInfo"`).
- **Deploy:** run `git diff -- game` first and confirm only intended files changed. Ask the user to close Quake 4 and 7-Zip. Back up `ABRACADABRA\game000.pk4`, replace `Gamex86.dll` inside it (PowerShell `System.IO.Compression.ZipArchive`, Update mode), and compare the SHA-256 of the pk4 entry against the build. Loose files go in `ABRACADABRA\def\` and `ABRACADABRA\guis\`, and they override pk4 contents.
- **Reuse before inventing.** The professor's rule: "the hard part is finding which 100 lines to change." Every item below lists the existing code to reuse.
- No git commits unless the user asks. The President is **unarmed**; that is a final design decision, so never suggest arming him.
- Stock data (defs, scripts, GUIs, strings, all 29 SP `.map` sources) is readable inside `...\Quake 4\q4base\*.pk4`. Extract in `ls *.pk4 | sort` order; the Git Bash `unzip` needs `'def/**'`, because `*` does not cross `/`.

## 1. Where we are
- **Done:** 5 squad defs (`def/ptp_squad.def`: Overwatch, Ram, Thunder, Doc, Wrench) and the `ptp_squad` console command (`Cmd_PTPSquad_f`, `game/gamesys/SysCmds.cpp`, registered in `InitConsoleCommands` next to `spawn`). The user confirmed `ptp_squad` works in game.
- Every squad member carries `"ptp_squad" "1"` and `"leader" "player1"`. `Cmd_PTPSquad_f` shows the idiom for finding them: loop `gameLocal.spawnedEntities` and test `ent->spawnArgs.GetBool("ptp_squad")`.
- **Still open from the deliverables:** a single-player map for the squad to live in, plus the items below.

## 2. Fix first: the desktop shortcut (blocking, small)
Live shortcut (`C:\Users\loren\OneDrive\Desktop\Quake4.lnk`), read read-only today:
- Target: `...\Quake 4\Quake4.exe`; Start in: the Quake 4 folder (correct).
- Arguments: `+set fs_game ABRACADABRA +set com_skipIntroVideo 1 corruption -skipmovies`

**Findings:**
1. A leftover **`corruption`** token sits in the middle of the arguments (from the old shortcut). In idTech4 a bare word after `+set …` is appended to that command's arguments, so the cvar value becomes `1 corruption -skipmovies`. Remove it.
2. **`com_skipIntroVideo` and `-skipmovies` do not exist in `Quake4.exe`** (searched the binary: 0 matches for both, no `*Intro*` or `*movie*` cvars at all). **The previous chat suggested `com_skipIntroVideo` and that was wrong.** Neither flag skips anything; drop both.
3. **Answered (user, 2026-10-14):** the shortcut loads ABRACADABRA and everything works, but the logo videos still play.
4. **Root cause:** the logos are not engine movies. `guis/mainmenu.gui` (newest copy in pak025) plays them from `onNamedEvent PlayIntro`: idlogo → raven_logo → bethsoft_logo on fixed `onTime` timers, about 34 s in total. `onNamedEvent NoIntro` goes straight to the menu. As in Doom 3, the engine sends `PlayIntro` at startup only when the command line holds nothing but `set` commands ("set commands won't override menu startup"). Every argument in the old shortcut was a `set`, so the intro always played.
5. **Tried and reverted: `+disconnect`** (a non-`set` command). Tested 2026-10-14: the logos **still played**, and then the Steam build showed a **CD key prompt** that blocked the game. **Never put non-`set` commands on the command line** (`+disconnect`, `+map`, `+devmap`, …); keep the arguments `+set` only.
6. **Current fix (data only, no command line):** a mod-local copy of the stock pak025 `guis/mainmenu.gui` at `ABRACADABRA\guis\mainmenu.gui`, with its source in `guis/mainmenu.gui` in the repo. Only the `onNamedEvent PlayIntro` body changed: it now runs the same block the stock intro runs when its last video ends (`video_bethsoft` `onTime +4500`: cursor on, `anim_in`, `ingameCheck`, `videoBlack`, `MenuMusic`). The rest of the file is byte-identical to stock, and q4base and corruption are untouched.
   - **Test 1 (2026-10-14):** the logos are gone, but the CD key prompt still appeared.
   - **Cause:** the `MenuMusic` window runs `music main_menu checkKeys`, and `checkKeys` pops the prompt if the CD-key check has not finished yet. Stock Quake 4 only ran it about 34 s in, after the logos. The same race explains the failed `+disconnect` run: the engine drops startup commands while the key is not yet validated, so the logos played anyway.
   - **Test 2:** no prompt at startup, but it **still prompted when returning to the main menu** from a game, even after a Steam "verify integrity of game files" (which passed clean).
   - **Final fix:** `MenuMusic` `onTime 10` is the **only** automatic `checkKeys` in the GUI (startup, end of intro, `MusicRestart` on returning to the menu). The other key call is the manual "CD Key" button. Both music lines now read `music main_menu` / `music main_menu_gameplay` with no `checkKeys`, and `PlayIntro` is back to the exact stock end-of-intro block (`resetTime "MenuMusic"`). The diff against stock is those three spots. **Awaiting test 3.**
   - **Key safety:**
     - Nothing we did writes to `q4base`; it is read-only for us (pk4 extraction goes to a scratch folder).
     - Quake4.exe rewrites `q4base\quake4key` itself on **every exit** (same second as `Quake4Config.cfg`).
     - The engine only reads `q4base\quake4key`. A copy in `ABRACADABRA\` is ignored and **must never be packaged** (it would ship the license key).
   - Replacing the `video/*.roq` files does **not** work: the GUI timers are fixed, so the result is about 34 s of black screen.
   - Do not rename or delete files in `q4base`; that affects the user's other mod.

**Deliverable:**
- The shortcut arguments are now just `+set fs_game ABRACADABRA` (the junk was removed).
- `PTP_Launch.bat` (repo root, with a copy in `ABRACADABRA\`) for submission, because a `.lnk` hard-codes this machine's path. The `.bat` looks for `Quake4.exe` one folder up and falls back to the default Steam path.
- `guis/mainmenu.gui` must also go into the submission pk4.

## 3. Unarm the President and keep him unarmed
**Implemented 2026-10-14** (`game/Player.cpp` only; built and deployed, pk4 hash verified; **awaiting the in-game check**):
- `Init`: `weaponEnabled = false`.
- Save restore: re-forced to `false` after `ReadBool`.
- `Event_EnableWeapon`: no longer re-arms (stock body kept in a `/* */` block); it only re-shows the crosshair.
- `Event_DisableWeapon`: no longer hides the crosshair.
- Both `WeaponIsEnabled() ? "showCrossCombat" : "crossHide"` sites now always show `showCrossCombat`, so the Attack order has an aim point. Camera cinematics never draw the cursor (`DrawHUD` returns at `gameLocal.GetCamera()`).
- Flashlight: left blocked for simplicity. Revisit only if the chosen map is dark.

**What exists:** `idPlayer::weaponEnabled` is a complete lockout. When false, `Weapon_Combat` returns early (`game/Player.cpp:6050`), next/prev/select weapon are blocked (5493, 5522, 5620, 5725), and the flashlight is blocked (12905). `SetWeapon` re-hides new weapons (1415). It is saved in savegames (2210 / 2486).

**What turns it back on (the "keep it that way" part):**
| Source | Where | Matters? |
|---|---|---|
| Player init sets `weaponEnabled = true` on every spawn / level load | `Player.cpp:1513` (constructor 1178) | **Yes, change this** |
| Script/event `enableWeapon` | `Event_EnableWeapon`, `Player.cpp:11422-11431` (also gives the blaster, un-hides, shows crosshair) | **Yes, guard this.** In stock scripts only `scripts/maps/medlabs.script` calls it (lines 134, 3171) and `disableWeapon` (3191, 3205) |
| Map entity `target_enablelevelweapons` | `game/Target.cpp:2028`; world key `no_Weapons` | Only mcc_1, mcc_2, medlabs use the key |
| `give` cheats, pickups | clear `no_Weapons` but never touch `weaponEnabled` | No, firing stays blocked |
| Loading an old savegame | `Player.cpp:2486` restores the saved value | Edge case: old saves would restore `true` |

**Recommended minimal change:** at `Player.cpp:1513` set `weaponEnabled = false`, and make `Event_EnableWeapon` (11422) a no-op for the enable (keep it from setting `weaponEnabled`/un-hiding). Optionally force `weaponEnabled = false` again right after the save restore (2486) so old saves cannot re-arm him. About 5 lines. The alternative of a single extra `&&` at `Player.cpp:6050` / `3985` keeps the flashlight working; the planning chat should weigh the flashlight (dark maps) against simplicity.

**Gotchas the planner must handle:**
- **Crosshair:** the plain crosshair is hidden whenever weapons are disabled (`Player.cpp:7291` and `7413`: `WeaponIsEnabled() ? "showCrossCombat" : "crossHide"`). The NPC talk cursor and name still work (`showCrossTalk` does not depend on it). But the **"Attack" order needs a visible aim point**, so those two sites need to show a crosshair in this mod (or the HUD draws its own dot).
- **Clicking NPCs still works** when unarmed: `Weapon_NPC` is dispatched before the `!hiddenWeapon` check (`Player.cpp:6335-6346`, talk at 6170). The risk is the early return at `Player.cpp:6310-6318` (`weapon == NULL && idealWeapon == -1`). The stock player spawns holding the blaster (`player.def` `"weapon" "weapon_blaster"`), so this should be fine; verify in game.
- **Medlabs** is the one stock map whose script re-arms the player. The guard on `Event_EnableWeapon` covers it, or just avoid that map.
- With the weapon lowered, the number keys `1`–`9`, `[` `]` and the mouse wheel (weapon select impulses) are free for the command menu (section 4).

## 4. Command menu: Attack, Protect, Wait, Scatter
**Renamed (user, 2026-10-14):** the old "Go" order is now **"Attack"**, with the same mechanism: the squad moves to the spot the President aims at and fights there.

### 4a. How the player issues orders (decided: keys 1–4 directly, no menu toggle)
- **Controls (user, 2026-10-14):** `1` Attack, `2` Protect, `3` Wait, `4` Scatter. The President is unarmed, so keys 1–4 (weapon slots) are dead and get repurposed. **No `ptp_menu` toggle and no menu-open state.**
- **Hook:** `PerformImpulse` sends `IMPULSE_0..12` to `SelectWeapon` (`Player.cpp:8459`), which already does nothing while `weaponEnabled` is false. Insert just before that line: `IMPULSE_0` → Attack, `IMPULSE_1` → Protect, `IMPULSE_2` → Wait, `IMPULSE_3` → Scatter.
- **Binds:** stock `default.cfg` (pak021) binds `1`–`4` to `_impulse0..3`, so graders need no configuration. **Gotcha:** the user's own `ABRACADABRA\Quake4Config.cfg` binds `4` to `_impulse4` and `5` to `_impulse3` (swapped versus stock). Restore stock (`bind 4 "_impulse3"`, `bind 5 "_impulse4"`) when this lands, with Quake 4 closed, because it rewrites the config on exit.
- **Fallback:** four console commands (`ptp_attack`, `ptp_protect`, `ptp_wait`, `ptp_scatter`, same pattern as `Cmd_PTPSquad_f`) for testing and the README.
- **The "menu" deliverable:** a small HUD panel listing "1 Attack  2 Protect  3 Wait  4 Scatter" with the active order highlighted (see 4c).
- The MP menu path (`game_startmenu` → `idGameLocal::StartMenu` `Game_local.cpp:3969`, gated `!isMultiplayer`) is no longer needed.

### 4-progress (2026-10-14)
- **Plumbing done** (`Player.cpp` / `Player.h` / `SysCmds.cpp`):
  - `ptpOrder_t` (Attack 0, Protect 1, Wait 2, Scatter 3) in `Player.h`.
  - `PerformImpulse` routes impulses 0-3 to `idPlayer::IssueSquadOrder` while `!weaponEnabled`.
  - `Cmd_PTPOrder_f` is one handler registered as `ptp_attack` / `ptp_protect` / `ptp_wait` / `ptp_scatter`; the command name picks the order.
- **How `IssueSquadOrder` works:**
  - It collects live `"ptp_squad"` AI and clears the previous order: `SetTether(NULL)`, then removes every entity with `"ptp_order_tether" "1"`.
  - Then it applies the order. Unimplemented orders print "not in yet".
- **`PTP_SpawnOrderTether(origin, radius)`** (file-static in `Player.cpp`) spawns the stock **`ai_tether_radius`** (`def/ai.def`) with `"location" "0"`, `"allowBreak" "0"` and `"ptp_order_tether" "1"`. `Player.cpp` now includes `ai/AI_Util.h`, as `spawner.cpp` does.
- **Wait: confirmed working in game (2026-10-14).** `SetLeader(NULL)` plus a 64-unit tether on each member's own spot.
  - Doc and Wrench still break Wait to heal the President when his health is low and he has no armor (confirmed, and desired).
- **Toggle (user request, 2026-10-14):** every key is a toggle.
  - Pressing the active order's key again turns it off. Every order first resets the squad to the default (no tether, `SetLeader(player)`, following the President).
  - The active order is stored per squad member as the spawnArg `"ptp_order"` (`-1` = following). spawnArgs are saved with entities, so no save-format change is needed.
  - A fresh `ptp_squad` starts at `-1`.
  - Built and deployed (pk4 hash verified); awaiting the in-game check.
- The Wait toggle is confirmed in game.
- **Protect: built and deployed, awaiting test (v2).**
  - **v1 (2026-10-14):** a single 160-unit tether. In game the squad bunched up unevenly and too close. A shared circle makes everyone stop at the nearest point inside it, on the side they came from.
  - **v2 mechanism:** an even **ring of slot tethers**, one per member, 192 units from the President at `360 / N` spacing starting at his view yaw. Each slot is an 80-unit `ai_tether_radius` **bound to the player** (`tether->Bind( this, false )`, unoriented, so the ring keeps its world orientation and moves with him). Each member takes the nearest free slot so paths don't cross. Leader stays the player.
  - **Known edge:** a slot pushed into a wall or onto a ledge with no reachable floor within 80 units leaves that member where they are until you move.
  - **Why this works without AI code changes:** inside the circle the squad keeps ranged attacks but drops follow, melee and flank. `allowBreak 0` keeps them from chasing enemies out of it. This avoids the "follow is dropped when an enemy is visible" issue in `FilterTactical`.
  - **Checked:** `AI.cpp:3596-3616` (an AI with a leader drops tethers when the leader is on the ground) only clears mover tethers (`aifl.tetherMover`). `SetTether()` clears that flag, so our tether is kept.
- **The Protect ring (v2) is confirmed in game:** an even ring formation is visible.
- **`ptp_squad` dropping Doc and/or Wrench: v3 built and deployed, awaiting test.**
  - **v1 cause:** they were the ±80° side spawn spots, skipped when a wall was within about 88 units.
  - **v2:** a smaller waist-height line check plus a second-row fallback. In game it printed `spawned 5/5`, but **Doc was invisible**.
  - **Why v2 failed:** a single line at waist height misses geometry at other heights, so Doc spawned overlapping the wall and ended up stuck inside it. "Spawned" only means `SpawnEntityDef` succeeded.
  - **v3, `PTP_FindSquadSpot` (`SysCmds.cpp`):**
    - It sweeps a **marine-sized box** (`char_marine_base` `"size" "32 32 72"`, so bounds -16..16 by 0..72) out from the player, 16 units up, colliding with `CONTENTS_SOLID|CONTENTS_MONSTERCLIP` (same `idTraceModel` + `idClipModel::LoadModel` + `gameLocal.Translation` pattern as `AAS_debug.cpp`). The spot must be at least 40 units out.
    - It then sweeps the box down up to 80 units onto the floor; a drop deeper than 64 units is rejected.
    - Finally, `gameLocal.Contents( …, MASK_MONSTERSOLID, player )` must be empty, so no overlap with solids or any body, including earlier squad members.
  - **Old squad hidden first:** the old squad is `Hide()`n before removal; `idAI::Hide` sets contents to 0 and unlinks the clip, so the old bodies don't block the new spots. Old order tethers are also removed on re-deploy.
  - **Fallback spots** at 160 units, relative to straight behind: -15, +15, 0, -130, +130, then 180 (in front, last resort). A member is only skipped if every spot fails.
  - This spawn logic will later back a checkpoint trigger that tops up the squad, so it must not fail in normal play.
- **Checkpoint commit `2ab40d3` (2026-10-14)** on `personal_deliverable_2`, containing only the 8 PTP files.
  - The project-upgrade files, `mpgame/gamesys` edits and `.vs/` noise that were already staged before this work were left staged and uncommitted, because they aren't PTP work. The user decides about those.
- **The `ptp_squad` v3 box-sweep spawn is confirmed:** all 5 are visible even at the problem wall.
- **Attack (key 1): built and deployed, awaiting test.**
  - **Aim spot:** `PTP_FindAttackSpot` (`Player.cpp`) traces from the eye along the view, 4096 units, `MASK_SHOT_BOUNDINGBOX`, the same pattern as `Cmd_AI_DebugFilter_f`. It steps back 24 units off the hit, then point-traces down up to 1024 units onto the floor.
  - **Reachability:** the spot must pass `squad[0]->PointReachableAreaNum()`. A bad aim (sky, no floor, no AAS) prints a message and **changes nothing**; the aim is validated before the previous order is cleared.
  - **The order:** `SetLeader(NULL)` and one shared 128-unit `ai_tether_radius` at the spot.
    - `allowBreak 1`: they leave the zone while an enemy is inside it, so they really engage, and return once it's clear.
    - `forceRun 1`: they run there.
  - `PTP_SpawnOrderTether` gained optional `allowBreak` / `forceRun` parameters (both false by default, so Wait and Protect are unchanged).
- **Attack is confirmed in game:** the squad runs to the aim point, fights there, and comes back on a second press of 1.
- **Scatter (key 4): built and deployed, awaiting test.**
  - **Slots:** an even ring 256 units from the President, starting at his view yaw. Each slot is pulled in to 32 units short of any wall hit by a waist-height trace, so no zone sits behind a wall.
  - **Zones:** each member gets a static 128-unit `ai_tether_radius` (not bound) with `allowBreak 1` and `forceRun 1`, and `SetLeader(NULL)`.
  - **Shared helper:** `PTP_TetherSquadToSlots( squad, slots, radius, allowBreak, forceRun, bindTo )` holds the nearest-free-slot assignment that Protect (bound to the player) and Scatter (unbound) now share.
- **Scatter v1 feedback:** too tight; near a wall it looked like Protect; the user wants **forward** fighting positions that don't crowd the President. Members also get stuck on props, which is partly stock Quake 4 AI.
- **Scatter v2: confirmed better in game (2026-10-14).**
  - **Shape:** a forward "arrowhead" arc from the view yaw: 0° at 448 units, ±35° at 384, ±70° at 320. That's about 600 units wide with 220–260 units between neighbors.
  - **Spot checks:** `PTP_FindScatterSpot` pulls each spot back 48 units off walls, drops it to the floor (512-unit down trace) and requires `PointReachableAreaNum`; it retries at half distance.
  - **Zones:** static 128-unit tethers with `allowBreak` and `forceRun`, leader NULL.
  - **Fallback:** members without a valid spot keep following (`GetTether() == NULL`, so `SetLeader(player)`).
- **All four orders are implemented, and each is a toggle.**
- **CD key prompt is back on `map game/airdefense1` (diagnosed 2026-10-14; no code changed yet, at the user's request):**
  - **No GUI involved:** every stock GUI was grepped. Only `mainmenu.gui` calls `checkKeys` / `promptKey`, and our deployed copy keeps only the manual "CD Key" settings button. So this prompt comes from the **engine** (Quake4.exe, not in the SDK).
  - **The key file is unchanged:** `q4base\quake4key` has the same hash as before the Steam verify, and Steam ships the same file to every owner.
  - **The exe has id's master-server key check:** `authing with the master..`, `auth key is invalid`, and `auth message from master. net_LANServer is enabled, ignored.` The built-in master is `q4master.idsoftware.com`. When the master answers "invalid", the next key check pops the prompt. That would explain why it's intermittent (it depends on whether and when the reply arrives).
  - ~~Likely fix: `net_LANServer 1`~~. **Wrong: it was the cause.** See RESOLVED below.
  - **LAN test result (2026-10-14): `net_LANServer 1` did NOT fix it.** The log goes to `q4base\qconsole.log` (the engine's choice).
    - **The "crash" is not a crash.** The log shows the map loading fully after `map`, then a clean, orderly shutdown with no error and no crash report.
    - That is id's stock behavior: **Cancel or Esc on the forced CD key prompt queues `quit`**.
    - Loading a savegame never prompted, but `map` did. Starting a new game runs id's **strict** key check, which needs an OK from the master server.
  - **The exe has 7 code references to `promptKey force`** (found by scanning `.text` for the string's address). The GUI `checkKeys` was only one of them; the rest are engine code we can't reach.
  - **No setting disables it:** the only related console variables are `net_LANServer`, `net_LANRepeater`, `net_menuLANServer` and `net_master0-4`.
  - **No registry CD key**, so the key lives only in `q4base\quake4key`, whose hash is unchanged.
  - **LAN mode ignores master replies**, so the strict check can't pass. The test also persisted `seta net_LANServer "1"`.
  - **Not doing:** exe patches or code that bypasses the key check.
  - **RESOLVED 2026-10-14: `map` works with no prompt** (confirmed by the user and the log).
    - **What works:** with `net_LANServer 0`, Quake 4 runs its key check at launch (`Opening IP socket` → `authing with the master..` → `no reply from auth`). No reply counts as OK, so `map`'s strict check passes.
    - **Final test log:** two `map game/airdefense1` loads, with `ptp_squad` and Scatter in between, and no prompt.
  - **Root cause of the persistent prompt: LAN mode stops the check from ever running.** The LAN test left `seta net_LANServer "1"` in the mod config. With it, no auth starts, the key never gets its OK, and `map` always prompts. **Never set `net_LANServer 1`.**
  - **Our DLL was ruled out.**
    - An automated harness swapped DLLs into `ABRACADABRA\game000.pk4`, launched with logging, checked for the auth line, closed the game, and restored our pk4 with a hash check.
    - Results: `eefd0b2` build, `2ab40d3` build, and the current deployed build were all `AUTH=True`.
    - An earlier "the DLL is the cause" conclusion was confounded by the leftover LAN config.
  - **Still possible, not seen in any log:** id's master server actually replying "auth key is invalid". If a prompt ever returns with LAN at 0, launch once with `+set logFile 2 +set developer 1` and look for that line in `q4base\qconsole.log`.
  - **Final state:** the shortcut and `PTP_Launch.bat` are `+set fs_game ABRACADABRA`, and the mod config has `seta net_LANServer "0"`.
  - **README note for graders:** keep multiplayer LAN mode off (`net_LANServer 0`). Quake 4's own CD key prompt quits the game on Cancel.
- **Key 4 bind fixed (2026-10-14):** the user's `ABRACADABRA\Quake4Config.cfg` now has `bind "4" "_impulse3"` and `bind "5" "_impulse4"` (stock). It was edited with Quake 4 closed and backed up first.
- **README.md written (2026-10-14):** concept (the help text verbatim), squad table, controls, console commands, install and launch, notes (LAN mode off, CD key prompt), building from source, and "coming soon". There's a copy in `ABRACADABRA\README.md`. Objectives get added once they're chosen.
- **HUD order panel (4c): confirmed in game (2026-10-18).** The panel shows top-left, the highlight follows keys 1-4, a second press clears it, and `ptp_squad` resets it. Save / load has not been tested in game yet.
  - **GUI:** `guis/hud.gui` is a byte-exact copy of stock `pak021.pk4:guis/hud.gui` plus one block, `windowDef ptp_orders`, placed just before the death-fade section (it's deployed loose to `ABRACADABRA\guis\hud.gui`).
    - The panel sits top-left at rect `8,8,294,22`, with four cells: `1 Attack`, `2 Protect`, `3 Wait`, `4 Scatter`.
    - The active cell gets an amber background and dark text, all through `visible ("gui::ptp_order" == N)` expressions, the same idiom as stock `p_armor`.
  - **C++ (`Player.cpp` / `Player.h`):**
    - `UpdateHudStats` sets the HUD state int `ptp_order` from the cached `ptpHudOrder`.
    - That value comes from the file-static `PTP_SquadOrder()`: the `"ptp_order"` spawnArg of the first live, non-hidden squad member, or -1.
    - It's rescanned every 250 ms (`ptpHudScanTime`), and `IssueSquadOrder` forces a rescan on the next frame.
    - Neither member is saved. A loaded save constructs a fresh player, which rescans right away, and the order itself survives in the squad's spawnArgs.
    - `ptp_squad` needs no change: the hidden old squad is skipped, so the panel clears on the next scan.
  - **Known limit:** stroggified maps (`player_strogg`) use `guis/hud_strogg.gui`. If the chosen map is one of them, add the same block to a copy of the stock `hud_strogg.gui` (pak014).
- **Next:** the map, objectives, extraction holdout, the README objectives section and pak001.pk4.

### 4b. How each order maps onto existing AI code (all in `game/ai`)
All squad iteration uses the `spawnedEntities` + `ptp_squad` tag idiom. Orders need to run **inside `idAI`** (a new public method or `friend`), because `MoveTo(pos)` is `protected` (`AI.h:974`), and `rvAITether` and `SetTether` / `SetLeader` are already public (`AI.h:830, 912`).

| Order | Mechanism (reuse) | Notes / traps |
|---|---|---|
| **Attack** (where you point and look) | Trace from `player->GetEyePosition()` along `viewAngles.ToForward()` (pattern: `Cmd_AI_DebugFilter_f`, `SysCmds.cpp`), take `tr.endpos`; `SetLeader(NULL)`; spawn a **radius tether** at that point (`rvAITetherRadius`, `AI_Util.h:157`, keys `radius`/`tetherRadius`, **`"location" "0"`**) and `SetTether()` it | Spawn at runtime with `gameLocal.SpawnEntityDef` (precedent for runtime tethers: `VehicleAI.cpp:45` spawns tether-class entities). Tether goals come from `rvAITether::FindGoal` via AAS, so the point must be on reachable floor; trace down to the floor and check the area (`PointReachableAreaNum`) before spawning. `"location" "0"` avoids dynamic-location creation, which the source calls "very, very bad" (`AI_Util.cpp:~560`). Do not set `autoBreak`: when an AI arrives, `autoBreak` clears the tether and the AI would drift back to its leader. Remove the previous tether entity on a new order |
| **Wait** (halt where you stand) | `SetLeader(NULL)` and a tight radius tether at the AI's **own** position | While tethered, `FilterTactical` strips follow/melee/hide/flank/retreat/ambush but keeps ranged attacks, so they hold and still shoot (`AI_States.cpp:1940-1941`). Alternative: `ScriptedStop`-style freeze, but `scripted` disables fighting and downgrades talk state (`AI.cpp:1914`) |
| **Protect** (circle and move with you) | Clear tether, `SetLeader(player)`, **tighter follow range** (`move.followRange`, default `"65 192"` on marines, `AI_Move.h:267`; only readable through `GetFollowRange()`, so add a public setter) | **Biggest design risk:** follow is dropped whenever an enemy is visible within `followRange[1] * 2` (`AI_States.cpp:1934`), so followers stop and fight where they stand instead of staying around the President. Options: relax that check for squad members (small change) or re-center a per-member tether on the President each frame. "Circle around you" needs per-member slot offsets (5 slots × 72°); stock follow has no formation code |
| **Scatter** (small distance away, free reign) | Per-member radius tether at distinct offsets around the President (about 250 units), `SetLeader(NULL)` | Radius tethers keep AI inside the circle while they fight; this is the native "free reign within a zone". The tether is static after the order |

**Order persistence:** a forced enemy gets overwritten within ~250 ms by auto-acquire (audit section 2), so the menu has **no "attack this target" order**; Attack (move-to-point) + tethers is the working design. Medic and Engineer (`rvAIMedic`) have their own movement rules for healing (`AI_Medic.cpp:407-447`): a tether can make them refuse to leave it unless `healObeyTether` is off, so test whether Doc and Wrench still heal under Wait and Scatter.

### 4c. Feedback (counts toward the "Custom UI" common deliverable)
HUD text can be bound to C++ state: stock `hud.gui` uses `text "gui::player_health"`, fed by `_hud->SetStateInt("player_health", …)` in `UpdateHudStats` (`Player.cpp:~3390-3450`). Add a `ptp_order` state string (current order name) and a small panel listing "1 Attack  2 Protect  3 Wait  4 Scatter" with the active order highlighted (this panel is the visible "command menu"); this needs a copy of the newest stock `hud.gui` (pak021) in `ABRACADABRA\guis\` or a small separate overlay GUI. `DrawHUD` returns before the overlay when `objectiveSystemOpen`, `disableHud`, a cinematic, a vehicle, etc. (`Player.cpp:3647-3705`).

## 5. Help screen: accurate content and the Tab key
**Implemented 2026-10-14** (built and deployed, hashes verified; **awaiting the in-game check**):
- **New `idPlayer::ToggleHelpScreen()`** (`Player.cpp`, next to `SetHudOverlay`). If any overlay is up, it hides it. Otherwise it shows `guis/help.gui` for one hour, which in practice means until toggled off. It uses the same `FindGui( …, true, false, true )` + `SetHudOverlay` path as the trigger.
- **Tab:** `case IMPULSE_19` calls it (the stock commented-out block is kept).
- **Fallback:** the `ptp_help` console command (`Cmd_PTPHelp_f`, `SysCmds.cpp`).
- **`guis/help.gui`:** the new text below. Title at 0.45, body at 0.26 in rect `20,68,440,245`, dismiss line at y 325. It is deployed loose to `ABRACADABRA\guis\`.

**What exists:** `guis/help.gui` is still the old "ROCKET MOD" text, so it is stale. `rvTrigger_HelpScreen::Event_Touch` (`game/Trigger.cpp:~1610-1635`) loads the GUI with `uiManager->FindGui( guiFile, true, false, true )` and calls `player->SetHudOverlay( gui, durationMs )`. `idPlayer::SetHudOverlay` is at `Player.cpp:13487`; `DrawHUD` draws it in single-player (`Player.cpp:3777-3783`, added by commit eefd0b2). `help.gui` is also deployed loose at `ABRACADABRA\guis\help.gui`. The GUI fits one 640×480 Desktop with a text window; the dismiss line currently says "dismiss automatically".

**Tab key (good news):** `TAB` is bound to `_impulse19` in `Quake4Config.cfg` and in stock `default.cfg`, but `case IMPULSE_19` in `idPlayer::PerformImpulse` (`Player.cpp:8508`) is an empty, commented-out block in this single-player code. The objectives wristcomm is on the `_ingameStats` key (`z`, `BUTTON_SCORES`), not Tab. So **Tab can be repurposed with no config or bind change**: put a toggle in `case IMPULSE_19`. Suggested shape: one new `idPlayer` helper (for example `ToggleHelpScreen()`) that `FindGui`s `guis/help.gui` and calls `SetHudOverlay( gui, <long duration> )`, and a second press calls `SetHudOverlay( NULL, 0 )`. A matching `ptp_help` console command (same pattern as `Cmd_PTPSquad_f`) gives the README a fallback.

**Content (user, 2026-10-14; use verbatim and keep it short):**
- `HelpTitle`: `PROTECT THE PRESIDENT`
- `HelpText`:
  > Hello, and welcome to Protect The President! You, the president, under the crushing weight of war stepped into the fray to complete vital objectives! But you are NOT a soldier, you have men ready to aid and defend you all the way to extraction. You will hit checkpoints to replenish your men as you advance, but try not to treat them like meat shields!
  >
  > CONTROLS:
  > 1 - Attack
  > 2 - Protect
  > 3 - Wait
  > 4 - Scatter
- `DismissText`: `TAB - show / hide this screen`

**Layout:** about 13 lines, the same count as the old Rocket Mod text. The current `HelpText` rect (y 70, height 270) overlaps `DismissText` (y 320), so shrink `HelpText` to about height 245 with `textscale` about 0.26, then tune in game. More GUI screens come once the objectives are chosen.

## 6. Suggested order of work for the planning chat
1. **Shortcut fix** (section 2): tiny, unblocks reliable testing. **2026-10-14:** `+disconnect` failed (CD key prompt) and was reverted. The mod-local `mainmenu.gui` intro skip and `PTP_Launch.bat` are deployed; the intro skip awaits an in-game test. If it fails, move on to Unarm.
2. **Unarm** (section 3): about 5 lines, plus the crosshair decision, which feeds the Attack order. **Done 2026-10-14; awaiting in-game check.**
3. **Help screen on Tab** (section 5): small, self-contained, reuses the trigger's code path. **Done 2026-10-14; awaiting in-game check.**
4. **Command menu** (section 4): the largest. Build one order at a time in the order Wait → Protect → Attack → Scatter, testing each with `ptp_squad` + `spawn monster_strogg_marine` before adding the HUD order panel.
5. Then back to: choose the single-player map, objectives, extraction holdout, README / pak001.pk4.

## 7. Verification checklist for whoever builds this
- **Build:** MSBuild succeeds with `BuildProjectReferences=false`; `idLib.lib` timestamp unchanged; deploy hash matches.
- **Shortcut:** launches into `ABRACADABRA` (console `fs_game` shows it, or `ptp_squad` exists); the main menu appears with **no** id / Raven / Bethesda logos. Same result from `ABRACADABRA\PTP_Launch.bat`.
- **Unarmed:** spawn in any map, hold left-click: nothing fires; `give all`, picking up a weapon item, and `enableWeapon` from a script do not re-arm; talk cursor and NPC names still show; aim crosshair visible for Attack.
- **Tab:** shows the help overlay, second press hides it; objectives wristcomm (`z`) is unaffected.
- **Orders** (with `ptp_squad` in a map with AAS, e.g. GUI_Test or `map game/airdefense1`, and `spawn monster_strogg_marine` for enemies): Wait → squad stops and still shoots; Attack → squad walks to the pointed spot, ignoring a bad (non-floor) target without a console `Error`; Protect → squad stays near you as you move, including during a fight; Scatter → squad spreads around you and fights freely. Keys 1–4 issue Attack/Protect/Wait/Scatter and never switch weapons. Re-issuing an order replaces the previous one and leaves no stray tether entities (`listMonsters` / entity counts). Doc and Wrench still heal under every order.
- A runtime `gameLocal.Error` drops to the console and kills the map, so every failure path in new code should print a `Warning` and bail.

## 8. Known unknowns (not verifiable from the repo)
- Whether the mod-local `mainmenu.gui` `PlayIntro` patch skips the logos cleanly (needs one launch).
- Exact in-game behavior of tether-vs-follow with `rvAIMedic` (needs a play test).

## 9. Contemporary weapons theme (midterm deliverable, 2026-10-19, branch `midterm_checkpoint`)
**Status:** built and deployed (pk4 hash verified, defs copied); **the user confirmed it works in game (2026-10-19).**

**Decisions (user):**
- **Demo:** through the squad and pickups. No dev arming switch; the President stays unarmed.
- **C++:** revert both "Rocket mod" changes.
- **Roster:** all 11 slots themed: Railgun → Barrett M82A1, Lightning Gun → TASER X26P, Dark Matter Gun → AT4, Napalm → M2 Flamethrower.
- **Thunder:** switched from plasma bolts to bullets.

**Player weapons (`def/weapons/*.def`, 11 files):**
- Each is a byte-copy of the newest stock file (the blaster from pak015, the rest from pak022) with only these keys edited: `inv_name`, `weaponname` (where stock has it), `fireRate`, `clipSize`, plus the per-weapon keys below.
- **Names:** plain-text `inv_name`, with no `.lang` file. Stock `weapon_napalmgun` already did this.
- **Per-weapon keys:**
  - M1911: `chargeTime 999` (no charged plasma shot), `damage_blaster` 8→12.
  - Shotgun: `hitscans` 9.
  - Barrett: `damage_railgun` 150.
  - TASER: `range` 300 and `def_damage damage_ptp_taser` (a new 3-damage def inheriting `damage_lightninggun`, so the Makron is unaffected).
  - AT4: `def_projectile projectile_rocket`.
- **Shared with enemies, so left stock:** `projectile_nail` and `damage_nail*` (Gunner, Harvester), `damage_lightninggun` (Makron), `projectile_rocket`, `hitscan_bullet` (vehicles).
- **Full table:** `README.md`, "Weapons".
- **The AR-15's semi-auto mode is stock:** zoomed fire sets `fireHeld` (`WeaponMachinegun.cpp:229-232`).

**Squad (`def/ptp_squad.def`, override keys only):**
- The guns show through `npc_description` in the hover text (`Player.cpp:7366`).
- **Overwatch:** Barrett M82A1, damage 60→90. The railgun trail is gone; it uses the stock bullet tracer with `tracerchance 1`.
- **Ram and Wrench:** Mossberg 590A1, `ammo` 8, pellet count 9.
- **Thunder:** M249 SAW. `def_attack_base` / `killswitch` → stock `hitscan_marine_bullet` (hitscan), with the machinegun sound and flash. `ammo` 200.
- **Doc:** AR-15 (M4A1). `ammo` 30, `fireRate` .075, bursts 3-10.

**C++:**
- `WeaponBlaster.cpp` and `WeaponRocketLauncher.cpp` are back to stock `Attack ( false, 1, spread, 0, 1.0f )`. The "Rocket mod" class example from `1e645ac` is undone.
- Built with `BuildProjectReferences=false`; `idLib.lib` still dated 2026-09-26 22:41.
- **pk4 backup:** `C:\Users\loren\source\repos\pk4_backups\game000_2026-10-19_before-weapons.pk4`.

**To check in game:**
- Hover text shows each gun.
- Thunder fires bullets (no blue bolts).
- Ram and Wrench reload after 8 shots.
- Overwatch shows a tracer.
- Pickups (`spawn weapon_shotgun` etc.) show the new names.
- No def warnings in the console.
- `give all` still can't make the President fire.

## 10. Objectives + extraction holdout (midterm deliverables, branch `objs_and_extr`, 2026-10-25/26)
**Status:** built and committed as `877314f`; confirmed end to end in game by the user (objectives, checkpoints, holdout with enemies from both spawn points, MISSION COMPLETE and back to the menu).

**Hook (no `.map` edit):**
- `idWorldspawn::Spawn` compiles `maps/<mapname>.script` and runs its global `main()` next to the stock level script, which is started by the worldspawn `"call"` key. So `maps/game/airdefense1.script` (namespace `ptp_mission`) runs on top of the stock level. The MP precedent is `pak019:maps/mp/q4xdm14.script`.
- Everything the mission needs is spawned at runtime from stock or mod defs.

**Mission flow (`run()`):**
1. **Intro:** wait until neither intro camera (`cin_camera_intro_cin_1`, `cin_opening`) has been active for 2 s; the same `isActive()` test as `playCameraWait`.
2. **`setupLevel()`:**
   - The stock objective entities are renamed, and a `target_null` takes over each name (`replaceEntity`), so the stock `sys.trigger( $objective… )` calls still hit an entity.
   - `target_endlevel_2` (the exit to airdefense2) is removed.
   - The Cortez scene is removed (`trigger_relay_5`, `npc_cortez`, `strogg_cortez_1`/`2`, `cortez_berserker`); the extraction zone is where he stands.
   - The intro Harvester gets `disableTarget()`.
3. **`setupMission()`:** the `ptp_mission` HUD-state entity (`target_null`), `target_ptp_checkpoint` and a `func_savegame`.
4. **The squad joins at the bunker doors**, when the stock `trigger_once_41` (which also fires the level's first save) has fired and removed itself. Deploying at the dropship left the squad stuck on the narrow ramp outside it.
5. **Objective 1:** 3 `item_ptp_document` (binder model) at the user's spots. Picked-up documents stay hidden, and that is what gets counted. The next one is renamed "Intel Document n of 3" for the pickup bar.
6. **Objective 2:** `ptp_computer` (Strogg `data_bank1.lwo`).
   - Within 100 units, the charge (`ptp_charge`, minepack) drops at the President's feet and the 10 s countdown starts.
   - Then `turret_exp.fx`, `radiusDamage` with stock `damage_exploding_barrel_large`, the console is removed and a fire `func_fx` stays.
7. **Objective 3:**
   - The HUD shows the distance to `EXTRACT` (Cortez's spot).
   - Inside 192 units: a checkpoint, then a `func_spawner` on 2 spawn points (`max_active 4`, `delay 2`, `skipvisible 0`, `spawn_enemy player1`, `spawn_neverDormant 1`).
   - After a `HOLD_TIME` (25 s) countdown: survivors are killed, the spawner is stopped, MISSION COMPLETE shows (a `trigger_helpscreen` spawned on the President with `guis/ptp_mission_complete.gui`), and after 8 s `target_sessionCommand "disconnect"` returns to the main menu.

**Checkpoints:** every completed objective, and entering the extraction zone, fires `target_ptp_checkpoint` (a fresh squad around the President) and the `func_savegame`. Between objectives the script waits 5.5 s, because the stock "objective complete" popup otherwise swallows the next objective's popup.

**C++:**
- `PTP_DeploySquad` (`SysCmds.cpp`), shared by `ptp_squad` and checkpoints. Spots must pass an aas32 route check that mirrors `idAI::TravelDistance`. Each member tries its own slot, then a 12-spot fallback ring, then any open spot ("placed anyway").
- `rvTarget_PTPCheckpoint` (`Target.cpp`), **registered in `idClass::RegisterClasses` (`Class.cpp`)**.
- `PTP_UpdateMissionHud` (`Player.cpp`) copies the `hud_*` keys of `ptp_mission` to the HUD.

**Data:**
- `def/ptp_mission.def`.
- The `ptp_mission` panel in `guis/hud.gui`.
- `guis/ptp_mission_complete.gui`.
- Squad `"followRange" "60 128"` (closer follow than the stock 192).

**Placement** (`getviewpos` eye positions; `floorBelow()` traces to the floor): constants at the top of the script. Holdout spawn points are checked with the spawner's own box test and lifted off uneven floor. A blocked one prints `ptp_mission: holdout spawn point N is blocked`.

**Test aid:** `set ptp_skip 1` skips objective 1 (also live during it), `set ptp_skip 2` goes straight to extraction, `set ptp_skip 0` restores the normal flow. Set it before `map game/airdefense1`.

**Gotchas found:**
- A new C++ entity class must be added to `idClass::RegisterClasses`, or it is "not found".
- A NULL entity passed to an event `'e'` parameter (e.g. `sys.trigger`) terminates the script thread. Retail Quake 4 only shows that warning with `developer 1`.
- A per-map script doesn't see the stock `#define`s (`true`, `false`, `MASK_*`…).
- Items with mesh models need `"mins"`/`"maxs"`.
- `target_tip` never shows.
- AI spawned out of the player's PVS goes dormant.
- The spawner silently skips spawn points that fail its box check.
- The start area can't be reached again after the medic door, hence extraction at Cortez's spot.

**Tried and reverted:**
- `"ignore_obstacles" "1"` on the squad (didn't fix the ramp).
- Click-to-plant on an interactive CPU-box screen (clicking never planted).

**Known limit:** squad pathing on the narrow ramp outside the dropship is unreliable; the bunker-door deploy avoids it.
