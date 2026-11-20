// Rotting Brain: a Roblox brainrot tycoon for make.fun bounty roblox-brainrot-01 (Node 22, standard library only).
// You are a brain. Buy meme brainrots off the Synapse Belt, rot them in your Lobe for Brain Cells per second,
// steal from rival Lobes, block thieves with Mind Block, and survive Touch Grass waves until you are Fully Rotted.
//
// This program hands the game in: it checks screenshots/, copies game.rbxl, src/, screenshots/ and PLAY.json to
// /output and writes /output/dossier.json with the vendored make.fun library. game.rbxl is saved from Studio,
// and src/ holds the same Luau as the place's scripts.
//
// Names under /output may hold only letters, digits, . _ and -, so dotted files (.DS_Store, .gitkeep) are skipped.
// Local run: mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, extname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const here = fileURLToPath(new URL('.', import.meta.url));
const out = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';
const SCREENSHOT_MAX_BYTES = 262144;

const notDotted = (path: string): boolean => !basename(path).startsWith('.');

function checkScreenshots(dir: string): void {
  const shots = existsSync(dir)
    ? readdirSync(dir).filter((name) => notDotted(name) && ['.png', '.jpg', '.jpeg'].includes(extname(name).toLowerCase()))
    : [];
  if (shots.length < 3 || shots.length > 4) throw new Error(`screenshots/ must hold 3 or 4 PNG/JPEG files, found ${shots.length}`);
  for (const name of shots) {
    const size = statSync(join(dir, name)).size;
    if (size > SCREENSHOT_MAX_BYTES) throw new Error(`screenshots/${name} is ${size} bytes, over ${SCREENSHOT_MAX_BYTES}`);
  }
}

checkScreenshots(join(here, 'screenshots'));

copyFileSync(join(here, 'game.rbxl'), join(out, 'game.rbxl'));
copyFileSync(join(here, 'PLAY.json'), join(out, 'PLAY.json'));
cpSync(join(here, 'src'), join(out, 'src'), { recursive: true, filter: notDotted });
mkdirSync(join(out, 'screenshots'), { recursive: true });
cpSync(join(here, 'screenshots'), join(out, 'screenshots'), { recursive: true, filter: notDotted });

// The scorer's caps (reference/gate.json); only text_max_bytes shapes the bytes.
writeFileSync(
  join(out, 'dossier.json'),
  buildDossier(out, { text_max_bytes: 65536, screenshots: { max: 4, max_bytes: 262144 }, max_instances: 500000, scripts_max_source_bytes: 8388608, scripts_max_path_chars: 1048576 }),
);
