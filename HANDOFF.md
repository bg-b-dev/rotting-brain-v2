# HANDOFF

Last update: session 13, 12:58 UTC. Studio place 115061750567662 saved to Roblox (version 53). All src/ files match Studio (checksums).

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

4. Session 3 client and events (all synced, playtest OK, no errors):
   - `StarterPlayerScripts/ClientMain.client.luau`: title banner, stats (cells, income, Lobe LV, rebirths), rot meter (Fully Rotted x3 text), alert banner (Alert remote, pop tween), feed (6 lines, dark backing), action bar E/F/L/U/R/B with live status and gray when not ready, Brainpedia 12x5 with ViewportFrame models (camera from `TopHeight`), "FOUND n/60", ✅ / 🔒 NOT FOUND. Hides StealPrompt on models whose `OwnerId` is the local player. Server income already has x3 in it, so the HUD does not multiply.
   - Capture switches (workspace attributes): `HudBand16x9` (Studio only, 16:9 HUD band), `HoldBanners` (alert stays), `EventsPaused` (scheduler skips).
   - `PlayerData.debugSet(player, {found = {ids}, cells=, rot=, ...})`: test setter, because BindableFunction args and returns are copies (`PlaytestControls:Invoke("PlayerData","get")` gives a copy, edits do nothing).
   - `EventService.luau`: touchGrass (18 s grass wall with flowers sweeps X -200..200, hits players below FLOOR2_HEIGHT: drop carry, pivot shove 14 studs + Sit 1.5 s; server velocity does not work on client-owned characters), brainFreeze (20 s, belt mutationChance 1, blue tint), brainLag (15 s, belt paused, gray tint, then one Epic-Mythic meme), dopamineRush (30 s, `LobeService.eventMultiplier = 2`). Banner through workspace attributes Event, EventColor, EventEnd. Scheduler: first at 45 s, then every 70-95 s, no repeat. `EventService.start(name)` for captures.

5. Session 4 Tier 1 polish (all synced, playtest OK, no errors):
   - Brain Freeze: `freezeModel()` adds a Glass ice shell over the Meme Lobe, icicles, Ice crystals along the belt, a frost sheet over the floor (y 0.12), snow ParticleEmitter at y 70; tint (165,210,255) saturation -0.15. Removed at the end.
   - Touch Grass: SurfaceGui "🌱 TOUCH GRASS!" x3 on both wall faces (reads well in shots).
   - Steal flow checked in play: hold StealPrompt on an NPC podium -> carry -> HomeZone places it, feed line OK. Upgrade, Brain Wash, Mind Block, Slap from the client Action remote OK.
   - Slap shove now uses PivotTo + Sit 1.5 s (server velocity did nothing). 🫧 does not render in Roblox: replaced by 🧼.
   - Test tip: in the Client datamodel, `prompt:InputHoldBegin()` / `InputHoldEnd()` triggers a ProximityPrompt. Set `EventsPaused` from the Server datamodel (client attributes do not replicate).

6. Session 5 Tier 2 (all synced, playtest OK, no errors):
   - `MemeBlender.luau` (new, init from ServerMain, in PlaytestControls): builds a blender at runtime at PLAZA_CENTER + (62, 0, 10) (mirror of the kiosks), glass jar, spinning blade, screen "MEME BLENDER · 3 SAME RARITY → 1 HIGHER" with a progress bar. Prompt "Blend 3" (hold 1 s): takes 3 brainrots of the lowest rarity that has 3 in your Lobe, spins them in the jar 10 s, then `LobeService.add` a random brainrot of the next rarity, 40 % mutation. Alert + feed line. One blend at a time (`busy`).
   - Catch card: `LobeService.add` pushes `caught = {id, mut, income}` on a first find; ClientMain shows a "✨ NEW BRAINROT! ✨" card on the right (model, name, rarity · mutation, income, caption), 4.5 s, held by `HoldBanners`. Viewport code is now `modelView()` (shared with Brainpedia tiles).
   - Touch Grass wall: SmoothPlastic (110,255,90) instead of dark Grass.
   - README: Blender, catch card, event list fixed, U and R keys.
   - Test tip: `PlaytestControls:Invoke("LobeService", "add", player, {id = n})` fills your Lobe (player Instances pass fine); `Invoke("MemeBlender", "blend", player)` runs a blend. `debugFill` needs a live lobe table, so it does NOT work through the hook.

7. Session 6 Brainrot vibe pass (plan "PRIORITY NOW", all 6 items done, synced, world rebuilt in Edit, playtest OK, no errors):
   - Item 1 character scale: `BrainrotModelKit.displayScale(rarity) = 2.2 * sqrt(rarity.scale)` (Common 2.2x, Fully Rotted 3.4x). Tag 25 % smaller. Lobes widened to 48 (podium columns ±20/±10/0), FLOOR2_HEIGHT 18 (was 14), floor-2 rows z 4.5 / 11.5. Podiums 7 wide. MemeBlender jar scale 0.25 (was 0.55).
   - Item 2 auras: Neon AuraDisc in rarity color under every brainrot, MutationRing (mutation color) under it, sparkle ParticleEmitter Rare+ (rate 3 x tier), Mythic+ thin LightBeam from feet to head only. Old AuraRing and Sparkles extras removed.
   - Item 3 colors: floor (40,10,60), FoldRidge veins lime (130,255,80) and thinner, skull wall (60,48,78), Lobe floors (35,15,50), back wall (22,8,32). `WorldBuilder.LOBE_ACCENTS` (8 colors) on GooEdge, Floor2Edge, pillars, new SideRails, ramp, podium bodies, PodiumRim (Neon), sign text. Podium top is white SmoothPlastic (white Neon blew out the frame).
   - Items 4 and 6 meme layer: `buildMemeLayer` in WorldBuilder, folder `BrainWorld.MemeLayer`: 12 floating LuckiestGuy signs (two-sided, face the plaza), 8 emoji billboards, yellow/lime floor chevrons from the belt to the 4 inner Lobes, 10 goo puddles and 8 neuron sparks inside the belt loop. ClientMain bobs every MemeLayer part with a `Bob` attribute (RenderStepped, client only).
   - Item 5 lighting: Atmosphere Color (90,30,140), Decay (40,15,70), Ambient (60,40,80), OutdoorAmbient (95,80,130).
   - Acceptance capture from (-22,36,30) looking at (-72,4,-42): characters lead, 5+ hues, OHIO / BRAIN ROT 100% / BOMBARDIRO readable, loop center filled.

8. Session 7 Most Rotted board (Tier 2, synced, playtest OK, no errors):
   - `MostRotted.luau` (new, init from ServerMain, in PlaytestControls): builds `workspace.MostRottedBoard` at runtime at PLAZA_CENTER + (34, 0, 30), faces the plaza center. SurfaceGui: "🏆 MOST ROTTED 🏆", two columns "🧠 BRAIN CELLS" and "📖 BRAINPEDIA", 8 rows (all Lobe owners), players in gold. Refresh every 2 s.
   - NPC kids get fixed base stats that grow with `time()` (server time; `os.clock()` is Studio uptime and blew up the numbers).
   - Good capture: camera (20, 15, 121) look at (34, 14, 142). A far capture right after play start showed the board blank once; capture again.
   - Checked by code: the Mind Block field sizes from LOBE_SIZE and h2; the Touch Grass wall (34 tall, 400 long, x ±200) covers the 48-wide Lobes and floor 2 at 18. Visual check still in the shot 2 setup.
   - README: Most Rotted line.

9. Session 8 bright daytime look (plan "PRIORITY NOW #2", synced, world rebuilt in Edit, playtest OK, no errors):
   - Lighting: ClockTime 14, Brightness 2.2, ExposureCompensation -0.2, Ambient (120,95,140), OutdoorAmbient (160,130,175), Sky (no sun/stars), Atmosphere Density 0.15 Color (255,190,230) Decay (255,150,210) Haze 0.2, Bloom 0.4/24/2.4, grade Saturation 0.45 Contrast 0.2. The plan's values (Brightness 3, Exposure +0.3, Haze 0.5) blew the pink floor to white: do not use them.
   - Floor bubblegum (255,150,200), FoldRidge (230,90,160), skull wall (210,180,255), belt white, Lobe floors (250,240,252), Lobe back wall = accent lerp lavender 0.6.
   - Signs: Lobe signs, kiosk boards, Meme Lobe sign and ROTTING BRAIN frame are solid color boards with white LuckiestGuy text and a dark stroke.
   - Name tags: solid rarity-colored box, dark border 3, white rarity line and name, yellow income line (green on Brainrot God), UIStroke 2.5 on every line, size 7.4x3 x sqrt(scale).
   - Checked in play: Brain Freeze reads pale cyan, Touch Grass wall bright green on pink.
   - Known look issue (old): the Meme Lobe folds stick out past the ball (Ball shape uses the smallest axis), so it reads like a cage. Optional fix: ball size uniform 60.

10. Session 9 Productivity Pixie raid (Tier 2, synced, playtest OK, no errors):
   - `EventService` event `homeworkRaid` (in the scheduler ORDER): banner "📋 HOMEWORK RAID · SLAP THE PIXIES [F]", 30 s, light red tint. One pixie every 4 s (6 max), built at runtime (blue body, glasses, bun, flapping Neon wings, clipboard, paper particles, label), `ScaleTo(2)`. Targets player Lobes first (NPC Lobes when no player has brainrots), skips Lobes with Mind Block up. Flies in at 30, grabs with `LobeService.beginSteal(lobe, slot, "pixie")`, flees outward 120 studs at 9 (about 13 s window), then `finishSteal`. Raid end: unfinished grabs go back (`cancelSteal`).
   - Focus Slap: `CarryService.onSlap` (set in `EventService.init`) hits the nearest pixie within 14 studs horizontal: pixie gone, brainrot back on its podium, bounty max(150, 5 s of item income), alert + feed.
   - Test: `PlaytestControls:Invoke("EventService", "start", "homeworkRaid")`. Good capture: camera (-35, 26, -30) look at (-90, 14, -70), about 11 s after the start.
   - README event line updated.

11. Session 10 Thought Bubbles (Tier 2, synced, playtest OK, no errors):
   - `ThoughtBubbles.luau` (new, init from ServerMain, in PlaytestControls): runtime shop "ThoughtBubbleShop" with 3 stands in front of the old GEAR kiosk (sign text now "💭 BUBBLES"), at PLAZA_CENTER + (-53, 0, -6 ± 5.5). Basic 2K / 30 s / Common-Rare, Gold 60K / 2 min / Rare-Legendary, Galaxy 2M / 5 min / Legendary-God; mutation 15/30/50 %.
   - A bought bubble (glass ball, neon core, two puffs, pad disc, countdown billboard) floats on one of 2 pads at Lobe local (±14, 0, -19), between the Lobe front and the belt. Pop: particle burst, `LobeService.add` (catch card on first find), alert "💭 POP! ...", feed line. Lobe full: waits and shows "LOBE FULL!".
   - Test: `Invoke("ThoughtBubbles", "speed", 10)` makes timers 10x faster; `Invoke("ThoughtBubbles", "buy", player, 1..3)` returns the pad or nil. Good captures: Lobe 2 pads from (-22, 16, -45) look at (-56, 7, -45); shop from (-34, 12, 106) look at (-56, 6, 106).
   - README feature line added.

12. Session 11 screenshots (all 4 done, 1280x720 JPEG, each under 256 KiB, TOUR.json lists them, starter PNGs removed):
   - `1-cover.jpg`: player Lobe 2 full (19 mutated brainrots + Dopamina Divina), Gold and Galaxy bubbles with countdowns, catch card "Gallina Aura Infinita", Fully Rotted x3, Lobe LV 4. Camera (-22, 31, -27) look at (-72, 9, -48).
   - `2-touch-grass.jpg`: static clone of the wall ("GrassStill" at x -12), event attributes set by hand, held alert. Camera (46, 26, 96) look at (-8, 4, 60), player at (6, 4, 70).
   - `3-brainpedia.jpg`: `debugSet found` 41 ids, pedia frame set Visible from the Client datamodel.
   - `4-steal.jpg`: stole Unicorno Neuronico (Mythic) from Lobe 4 with `StealPrompt:InputHoldBegin()`, Mind Block on the home Lobe (pink field), held "STOLEN! RUN HOME!". Belt items moved to ServerStorage for the shot (restored after). Camera (-18, 15, 18) look at (-50, 9, -20), player at (-41, 4, -6).
   - Capture recipe: `scratchpad/shot.sh` (lost after reboot): the 16:9 HUD band in a 1561x1080 capture is y 130..1008; `sips -c 878 1561 --cropOffset 130 0`, then `sips -z 720 1280 -s format jpeg -s formatOptions 56..80` until the file is <= 262144 bytes.
   - Capture tips: capture lag is 3-6 s, so moving events (Touch Grass wall) need a static clone. Rot climbs about 2/s with 20 items and Fully Rotted keeps re-firing its held alert: hide it from the Client datamodel (TextLabel with "INCOME x3", Visible false). `PlayerData.feed` lines through PlaytestControls replace spam in the feed. `PlayerData.push(p, {caught = {...}})` shows a catch card without a free slot. `debugSet {mindBlockReady = 0}` + `Invoke("CarryService", "mindBlock", p)` re-arms Mind Block.

13. Session 12 plan PRIORITY NOW #3 and #4 A/B (synced, playtest OK, no errors). The 4 committed shots are now OUT OF DATE.
   - #3 Brainpedia locked tiles: gray tile (95,95,104), model ImageColor3 (150,150,160) ImageTransparency 0.35, real name always, status line "NOT FOUND" or "+🧠X/s", 🔒 badge top right, ✅ for owned. Checked in a capture. Mutation dots skipped: `found` has no mutation data.
   - #4 A tags: 10.4x4.2 x sqrt(scale) (1.4x), MaxDistance 60, rarity line small, name and "+🧠X/s" with stroke 3.5. `attachNameTag(..., stagger)`: LobeService passes `slot % 2 == 0`, the staggered tag sits 2.4 x sqrt(scale) higher.
   - #4 B HUD: title 50 tall, "🧠 ROTTING BRAIN 🧠" big on the left, feature list small. Event line always on under the title: "NEXT EVENT: 🧊 BRAIN FREEZE · 0:24" (EventService picks the next event first and sets workspace attributes NextEvent, NextEventAt) or the live event. Stats and QUESTS panels on the left (0.24 wide). Feed: max 4 lines, own backing each, under the quests. Right menu of 7 colored buttons (SHOP, UPGRADES, BRAINPEDIA n/60, BLENDER, BUBBLES, BRAIN WASH, MOST ROTTED), 36 tall: upgrade/wash/pedia run the action, the rest show a hint alert. Catch card moved left of the menu (x 0.84).
   - Quests: `PlayerData.QUESTS` (Steal 1 brainrot +500, Run 3 blends +5K, Survive Touch Grass +2K), `d.quests = {0,0,0}`, `PlayerData.quest(player, i)` from CarryService (steal placed), MemeBlender (blend done), EventService (Touch Grass end, players not hit). Snapshot field `quests`. `debugSet {quests = {1, 2, 0}}` works.
   - Capture note: UI pixel offsets render about 1.7x in the 1561x1080 capture. With 7 menu buttons at 48 tall the menu hit the action bar; 36 fits (not yet seen in a capture after the change).

14. Session 13 plan PRIORITY NOW #5 A and B, then all 4 shots retaken (synced, playtest OK, no errors):
   - A: title card "🧠 ROTTING BRAIN 🧠" at x 140 (clears the Roblox menu), 13 feature chips in 2 rows right of it (`CHIP_ROWS` in ClientMain, width by text length).
   - B: Brainpedia header cards (📖 BRAINPEDIA · gold FOUND n/60 · green MY LOBE n/20 +🧠X/s · red X closes), each tile has a dark strip with the rarity name (rarity color) and +🧠X/s (green), green ON LOBE badge (from the player's own StealPrompt models), footer with 8 rarity chips and the 8 mutations with multipliers (RichText, mutation colors). Pedia 0.74 tall.
   - Shots: 1-cover (player carries Mammut Midollone in front of Lobe 2, catch card), 2-touch-grass, 3-brainpedia 41/60, 4-steal (STOLEN! RUN HOME!, Mind Block ON). Committed and pushed.
   - Capture script: `scratchpad/shot.sh out.jpg` crops the newest capture in tool-results; JPEG quality steps down to 38 (q 56 was still over 256 KiB).

## Next step

SHOTS DONE at 12:58. The plan says: stop here. The user uploads the thumbnail (1-cover.jpg) and saves game.rbxl.
Left for a later session only if the user asks: README final check (L for Mind Block, quests, systems menu, chips).
Known small thing: the U button shows 🧠150 after `debugSet lobeLevel` (cost is not recomputed by debugSet). Only test data, not a game bug.

## Sync method (important)

- No Rojo; Studio HTTP to GitHub is blocked (Assistant allowlist). Write the file in `src/` first, then push the SAME text with execute_luau (`m.Source = [==[...]==]`, split big files over several calls through a StringValue), and compare `#s` plus checksum `h = (h*31 + byte) % 2147483647` with `./check-sync.sh`.
- Small changes: same plain find/replace on both sides (python locally, the Studio MCP `multi_edit` tool with the same old/new strings in Edit), then compare checksums. The Studio id changes when Studio reconnects: call list_roblox_studios again.
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

- None known.

## Studio state

- Edit mode. ServerMain enabled. ClientMain LocalScript in StarterPlayerScripts. EventService, MemeBlender, MostRotted and ThoughtBubbles ModuleScripts in ServerScriptService.
