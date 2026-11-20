# HANDOFF

Last update: session 2, 06:56 UTC. Studio place 115061750567662 saved to Roblox (version 39). All src/ files match Studio (checksums).

## Done

1. Session 1: starter files, README badges, Studio wipe, WorldBuilder (world in Edit mode, `workspace.BrainWorld`), RarityConfig, MutationConfig, NumberFormat, BrainrotCatalog (60 rows), BrainrotModelKit.
2. Session 2: kit pushed and tested with a 60-model lineup (lineup deleted). Kit fixes: pivot at the feet (`body.PivotOffset`), TopHeight measured before rarity extras, tag anchor parented before WorldPosition, tag size and height scale with sqrt(rarity.scale), smaller AuraRing, thin LightBeam, new `leaf` prop.
3. Session 2 server (all synced, playtest OK, no errors):
   - `ReplicatedStorage/Remotes.luau`: folder `RemoteEvents` with Action (client -> server name), State (snapshot), Feed (text, color), Alert (text, color, seconds).
   - `PlayerData.luau`: data per player, DataStore `RottingBrain_v1` (skipped in Studio), `push(player, extra)` sends the snapshot: cells, rot, rebirths, lobeLevel, stored, income, lobe, found (id list), fullyRotted, mindBlock, mindBlockCooldown, slapCooldown, upgradeCost, brainWashCost, collected.
   - `LobeService.luau`: 8 Lobes, NPC kid owner + 6-9 random brainrots in each free Lobe, player gets inner Lobes first (2,4,5,7,...), podium models with Steal prompt (hold 0.8 s), model attribute `OwnerId`, sign "LOBE n · NAME", 1 s tick: income into the pad (`stored`), rot meter, Fully Rotted x3 for 20 s. `debugFill(lobe, {{id, mut}, ...})` for captures.
   - `SynapseBelt.luau`: loop spawn every 2.2 s, speed 7, faces the loop center (checked), tag line "BUY 🧠price · +inc/s", Buy prompt. `paused`, `speed`, `spawnEvery`, `mutationChance`, `luck` fields are for events.
   - `CarryService.luau`: carry over head (weld), place on entering own HomeZone, steal from rival/NPC Lobes ("STOLEN! RUN HOME!"), Focus Slap (range 10, cooldown 3 s, drops a stolen brainrot), Mind Block (10 s, cooldown 35 s, field transparency 0.68, pushes intruders out).
   - `ServerMain.server.luau`: pcall per require and init, actions `slap`, `mindBlock`, `upgrade` (cost 150 x 3.2^(lv-1), +25 % income per level), `brainWash` (cost 250K x 6^rebirths, +50 % income per rebirth), `collect`. Studio-only `ServerStorage.PlaytestControls` BindableFunction: `Invoke(serviceName, key, ...)` calls `service[key](...)`, or sets a field when args are given.

## Next step

1. Client: `src/StarterPlayerScripts/ClientMain.client.luau` (LocalScript) with the HUD from the plan's Tier 1 list: title banner, cells + income, rot meter, Lobe LV, big alert banner (Alert remote), feed with dark backing (Feed remote), colored action bar (E Buy/Steal, F Focus Slap, L Mind Block, U Upgrade, R Brain Wash, B Brainpedia) with cooldown status, Brainpedia 12x5 grid ("FOUND n/60", owned in color + ✅, others gray + 🔒 "NOT FOUND"). Keys send Action names above. Hide StealPrompt on models whose `OwnerId` is the local player. Add the Studio-only 16:9 HUD band attribute (lesson 17).
2. EventService (`init` is already called by ServerMain if the module exists): Touch Grass Wave, Brain Freeze, 1-2 more, event banner, Studio-only pause switch (lesson 19).
3. Then Tier 1 polish, Tier 2 if time, screenshots by 12:30.

## Sync method (important)

- No Rojo; Studio HTTP to GitHub is blocked (Assistant allowlist). Write the file in `src/` first, then push the SAME text with execute_luau (`m.Source = [==[...]==]`, split big files over several calls through a StringValue), and compare `#s` plus checksum `h = (h*31 + byte) % 2147483647` with `./check-sync.sh`.
- Small changes: same plain find/replace on both sides (python locally, `string.find(s, old, 1, true)` in Studio), then compare checksums.
- New Scripts: push with `Disabled = true`, enable after all modules are in.
- Rojo names: `X.luau` = ModuleScript, `X.server.luau` = Script, `X.client.luau` = LocalScript; folder = service.
- Kit tests in Edit: clone the ReplicatedStorage modules into a ServerStorage folder, require, destroy the folder. Build test models at y=80 (the plaza floor sits above y=0 near z=150).
- Commit messages: no attribution trailer (user rule; the auto classifier blocks it).

## Key decisions

- Layout (WorldBuilder constants): belt loop x ±38, z -105..55; Lobes 1-4 left (x -120/-68), 5-8 right (x 68/120), rows z -45 and 15, front (-Z local) faces the belt. Podium top = lobeCFrame * podiumLocal * (0, 2.9, 0).
- Keys follow design section 9: E interact, L Mind Block, F Focus Slap, U upgrades, R Brain Wash, B Brainpedia. README controls table: check it says L for Mind Block.
- Income per row is computed from the rarity range (log spread); price = income x rarity multiplier (5..30) x mutation multiplier on the belt.
- Name tags: BillboardGui on an Attachment, AlwaysOnTop false, 9x3.6 studs x sqrt(scale) (lesson 18).

## Open bugs

- None known. The client is not written, so actions are only reachable through PlaytestControls.

## Studio state

- Edit mode. ServerMain enabled. No LocalScripts yet.
