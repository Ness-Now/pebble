# PebbleLab — Codex instructions

Objective:
Transform Pebble into an AI/simulation laboratory while preserving the original game.

Rules:
- Do not modify rendering, audio, resource packs, or packaging unless explicitly asked.
- Prefer adding new files/modules over rewriting existing systems.
- Keep PebbleCore deterministic.
- Never reorder block/item/entity/biome registrations.
- Never use PEBBLE_REGOLD unless explicitly instructed.
- Run `swift build` after structural changes.
- Run `swift run -c release pebsmoke` after core simulation changes.
- Keep each change small and reviewable.
- First goal: create a headless executable target called PebbleLab.

Architecture:
- PebbleCore: existing deterministic engine.
- Pebble: existing macOS/Metal 3D game.
- PebbleLab: new headless simulation runner.