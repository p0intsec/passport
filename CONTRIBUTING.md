# Contributing

Thanks for your interest! `passport` is a single bash script and the goal is to keep it that way: easy to read, no dependencies beyond `bash 4+`, `curl` and `python3`.

## Before opening a PR

```bash
bash -n passport
shellcheck -S warning passport examples/*.sh
./passport --help
./passport availability KZ
./passport KZ https://example.com
```

- CLI output, options and docs are in US English.
- Automated tests must not send requests to third-party systems (CI only runs local checks).
- Never put tokens, internal IPs or real hostnames in examples — use `example.com`.
- Be nice to the public APIs (Globalping, check-host.net): no bursts, no load generation.

## Ideas

- `--json` output for integration with other tools.
- Optional Globalping token (higher quota) via environment variable.
- `--watch` mode to follow a URL for a few minutes.
