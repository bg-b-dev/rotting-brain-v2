# HANDOFF

Last update: session 1, 06:3x UTC. Studio place 115061750567662 saved to Roblox (version 35).

## Done

1. Starter copied into the repo (it was missing), PLAY.json, .makefun/owner.json, main.ts (new header + screenshot check), README (3 badges + bounty link).
2. Studio wiped: all old scripts, old BrainWorld, old Lighting children, Terrain.
3. Design step 1 (world): `src/ServerScriptService/WorldBuilder.luau`, built in Edit mode into `workspace.BrainWorld` (955 instances): floor folds, goo, skull wall with "3:07 AM" eye sockets, Meme Lobe, Synapse Belt loop, 8 two-floor Lobes (20 podiums each, sign, collect pad, MindBlockField, HomeZone), plaza (spawn, goo fountain, neon "ROTTING BRAIN" sign, 3 kiosks), Productivity HQ, Deep Subconscious gate. Lighting: ClockTime 3:07, lesson-21 values.
4. Design step 2 (part): ReplicatedStorage `RarityConfig`, `MutationConfig`, `NumberFormat`, `BrainrotCatalog` (60 rows) written AND pushed to Studio (checksums match).
5. `src/ReplicatedStorage/BrainrotModelKit.luau` (39 KB) written and committed, NOT yet pushed to Studio.

## Next step

1. Push BrainrotModelKit to Studio (see "Sync method"), then build a lineup of all 60 in Edit mode (e.g. 6 rows of 10 at z=150..170 near the plaza, in a temp folder), capture once, fix kit bugs (Wedge body front face, feature offsets), delete the lineup.
2. Rest of step 2: Remotes, DataService, LobeService, SynapseBelt, CarryService, BrainCellEconomy, ServerMain (Script, pcall per service, `WorldBuilder.ensureWorld()`), client HudController + ClientMain. Then Tier 1 order from the plan.

## Sync method (important)

- No Rojo installed; Studio blocks localhost HTTP. So: write the file in `src/` with Write/Edit first, then push the SAME text with execute_luau (`m.Source = [==[...]==]`), and compare `#s` plus checksum `h = (h*31 + byte) % 2147483647` with `./check-sync.sh` output.
- Small changes: patch both sides with the same plain find/replace (sed locally, `string.find(s, old, 1, true)` in Studio), then compare checksums.
- Rojo names: `X.luau` = ModuleScript, `X.server.luau` = Script, `X.client.luau` = LocalScript; folder = service.
- Run builders in Edit by cloning the module into ServerStorage, `require`, then destroy the clone.

## Key decisions

- Layout (WorldBuilder constants): belt loop x ±38, z -105..55; Lobes 1-4 left (x -120/-68), 5-8 right (x 68/120), rows z -45 and 15, front (-Z local) faces the belt. Inner Lobes (2,4,5,7) go to players first.
- Keys follow design section 9: E interact, L Mind Block, F Focus Slap, U upgrades, R Brain Wash, B Brainpedia. README controls table still says Q for Mind Block: fix to L.
- Income per row is computed from the rarity range (log spread); price = income x rarity multiplier (5..30).
- Name tags: BillboardGui on an Attachment, AlwaysOnTop false, world-sized 9x3.6 studs (lesson 18).

## Open bugs

- None known. Kit is untested in Studio.

## Studio state

- Edit mode, no scripts run at runtime yet (no ServerMain). ServerScriptService has WorldBuilder only; ReplicatedStorage has 4 modules.
