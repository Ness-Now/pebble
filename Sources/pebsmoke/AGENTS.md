# pebsmoke rules

- Never delete, bypass, weaken, rename away, or conditionally skip an existing check.
- Cover new deterministic runtime risks with focused checks, including failure paths and stable ordering where relevant.
- Keep all inputs seeded and all expectations deterministic.
- Never set `PEBBLE_REGOLD`, regenerate a golden, or accept a golden change as a routine fix.
- Preserve the exact pass/fail accounting: every check increments exactly one counter, the final totals are printed, and any failure exits nonzero.
- Report failures and the exact final check count honestly; never mask a failing section or substitute a partial run.
