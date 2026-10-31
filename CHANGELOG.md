# Changelog

## 2.0.0 — 2026-10-31

- **Breaking:** the whole CLI is now in US English — commands (`availability`, `request`, `trap-test`), options (`--country`, `--node`, `--probes`, `--residential`, `--path`, `--canary-text`, `--expect-bait`, `--expect-block`, `--control`, `--on-finish`), output and hook variables (`PC_PATH`, `PC_START_MS`, `PC_PROBE_*`).
- `request --country` accepts several comma-separated countries.
- Example hook moved to `examples/generic-unblock.sh`.

## 1.0.0 — 2026-10-31

- Shortcut `passport CC[,CC...] URL`: request from one or more countries.
- `availability [CC]`: dashboard of online countries/servers (Globalping + check-host.net), datacenter vs. residential.
- `request`: GET/HEAD from a country or node, multiple probes.
- `trap-test`: 4-step honeypot/WAF validation (canary, bait, block of the same probe, control), finish hook, CI-friendly exit code.
- Datacenter probes by default.
