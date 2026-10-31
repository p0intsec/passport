# passport

> **Troubleshoot any URL from any country** — straight from your terminal, no account, no API token.

Developed by **[p0intsec](https://github.com/p0intsec)**.

```
$ passport KZ https://example.com
  KZ Almaty             G-Core Labs                    AS202422  → HTTP 200  108 ms

$ passport BR,DE,JP https://example.com
  BR Sao Paulo          Oracle                         AS31898   → HTTP 200  25 ms
  DE Falkenstein        Hetzner Online                 AS24940   → HTTP 200  58 ms
  JP Tokyo              xTom                           AS3258    → HTTP 200  29 ms
```

`passport` answers questions like *"does the site load from Kazakhstan?"*, *"is our geo-blocking actually working?"*, *"is latency in Asia bad only for us?"* and *"is that country/ASN WAF rule live?"*. It also ships a **trap test** mode that validates honeypot/WAF traps end to end in four steps:

```
$ passport trap-test --host app.example.com --country KZ --canary-text my-canary

passport — trap test
  host: app.example.com   bait: /wp-login.php   origin: country KZ   control: US

1) Canary (/robots.txt)
  ✔ canary text found — host is behind the protection
2) Bait from KZ
     probe: Almaty/KZ — Scalaxy (AS58061)
  ✔ HTTP 200 in 5076 ms
3) Same probe requests /
  ✔ blocked (HTTP 403)
4) Control: US requests /
  ✔ HTTP 200 in 1320 ms (Buffalo/US)
All good.
```

---

## Table of contents

- [Why](#why)
- [Install](#install)
- [Shortcut: `passport CC URL`](#shortcut-passport-cc-url)
- [Commands](#commands)
  - [`availability` — which countries are online right now](#availability--which-countries-are-online-right-now)
  - [`request` — send a request from a country](#request--send-a-request-from-a-country)
  - [`trap-test` — 4-step honeypot/WAF validation](#trap-test--4-step-honeypotwaf-validation)
- [`--on-finish` hook (e.g. unblock the test IP)](#--on-finish-hook)
- [How it works](#how-it-works)
- [Limits and gotchas](#limits-and-gotchas)
- [Responsible use](#responsible-use)
- [Development](#development)

---

## Why

If you run a WAF, a honeypot, geo-blocking or per-country rules, you keep needing answers like:

- *"Can a visitor from Kazakhstan open the site?"*
- *"Is the country block rule really enforced?"*
- *"When an IP hits the trap, is it blocked everywhere — and only that IP?"*

Testing from your own machine doesn't cut it: you always exit from the same country, often through a VPN/ZTNA (Cloudflare WARP, Zscaler, …) that the protection itself treats differently. `passport` fires the request from **public servers around the world**, in the country you pick, and lays out the result.

It relies on two free, public networks:

| Network | Reach | How you pick | Origin type |
|---|---|---|---|
| [**Globalping**](https://globalping.io) | ~5,000 probes, ~120 countries | country code (`--country KZ`) | datacenter **and** residential (volunteers) |
| [**check-host.net**](https://check-host.net) | ~50 nodes, ~30 countries | node name (`--node kz1`) | datacenter |

## Install

Requirements: **bash 4+**, **curl** and **python3** (standard library only). Linux, macOS (with Homebrew bash) and WSL.

```bash
git clone https://github.com/p0intsec/passport.git
cd passport
./passport --help

# optional: put it on your PATH
sudo ln -s "$PWD/passport" /usr/local/bin/passport
```

No account and no token needed — both APIs are public.

## Shortcut: `passport CC URL`

The fastest way — one or more comma-separated countries, one probe per country:

```bash
passport KZ https://example.com
passport BR,US,DE,JP,ZA https://example.com/api/status
```

Same as `passport request --country KZ --url https://example.com`. Run `passport availability` to see which countries have probes right now.

## Commands

### `availability` — which countries are online right now

```bash
passport availability          # full dashboard
passport availability KZ       # details for one country
```

The dashboard merges both networks by country:

```
  Availability right now — check-host: 48 nodes · Globalping: 5391 probes in 121 countries

  CC    check-host               Globalping DC  resid.
  ----  ------------------------ ------------- -------
  BR    br1                                 78     102
  KE                                         0       5  (residential only)
  KZ    kz1                                  8       8
  MA                                         2       0
  ...
```

- **check-host**: nodes available in that country (use with `--node`).
- **Globalping DC / resid.**: how many datacenter and residential probes are online now.
- **(residential only)**: the country only has probes on home connections — see [Responsible use](#responsible-use).

Country details show city, provider and ASN for every origin:

```
  KZ Kazakhstan
  check-host.net (use --node <node>)
    kz1    Karaganda            185.120.77.165   AS203087
  Globalping (use --country KZ)
      2x datacenter  Almaty               Scalaxy                              AS58061
      2x datacenter  Almaty               G-Core Labs                          AS202422
      1x residential Astana               Kazakhtelecom                        AS9198
```

> Availability changes all the time (probes come and go). A country with no origin today — Algeria (`DZ`), for instance — shows up empty; use a neighbor (`MA`, `TN`).

### `request` — send a request from a country

```bash
passport request --url https://example.com/ --country KZ
passport request --url https://example.com/ --country DE --probes 3
passport request --url https://example.com/ --country BR,DE,JP
passport request --url https://example.com/ --node kz1
passport request --url https://example.com/status --country BR --method HEAD
```

```
  KZ Almaty             Scalaxy                        AS58061   → HTTP 200  388 ms
  KZ Almaty             G-Core Labs                    AS202422  → HTTP 200  129 ms
```

Handy for: checking geo-blocking, per-region latency, whether a country/ASN WAF rule is active, or whether a site behaves the same everywhere.

| Option | Default | |
|---|---|---|
| `--url URL` | — | required (`https://` is assumed when omitted) |
| `--country CC[,CC…]` / `--node NODE` | — | pick one |
| `--method GET\|HEAD` | `GET` | |
| `--probes N` | `1` per country | Globalping only |
| `--residential` | off | allow residential probes |

### `trap-test` — 4-step honeypot/WAF validation

For setups with a **trap**: a path no legitimate user ever requests (e.g. `/wp-login.php` on a site that isn't WordPress) that makes the protection block the requesting IP.

```bash
passport trap-test --host app.example.com --country KZ --canary-text my-canary
passport trap-test --host app.example.com --node tr1 --path /.env
```

| Step | What it does | Expected |
|---|---|---|
| 1. canary | `GET /robots.txt`, looks for `--canary-text` | text found = host is behind the protection. **If not, the run stops here** and nothing is triggered |
| 2. bait | the probe requests the trap path | `--expect-bait` (default `200`, the decoy) |
| 3. block | **the same probe** requests `/` | `--expect-block` (default `403`) |
| 4. control | a probe from **another country** requests `/` | 2xx/3xx — only the trapped IP is blocked |

How step 3 guarantees the **same IP**: on Globalping, the next measurement reuses the previous one's probes (`locations` = previous measurement id); on check-host, the node is fixed.

Exit code **0** when every step passes and **1** otherwise — usable in CI or scheduled checks.

| Option | Default | |
|---|---|---|
| `--host HOST` | — | required |
| `--country CC` / `--node NODE` | — | pick one |
| `--path P` | `/wp-login.php` (Globalping), `/.env` (check-host) | trap path |
| `--canary-path P` | `/robots.txt` | |
| `--canary-text T` | — | without it step 1 is skipped (not recommended) |
| `--expect-bait N` | `200` | |
| `--expect-block N` | `403` | |
| `--control CC` | `US` | |
| `--on-finish CMD` | — | see below |
| `--residential` | off | |

## `--on-finish` hook

After the run, the test origin **stays blocked** by your protection. Since every product unblocks differently (dashboard, API, IP list…), `passport` doesn't do it on its own: it runs the command you pass to `--on-finish`, with these variables:

| Variable | Content |
|---|---|
| `PC_HOST` | tested host |
| `PC_PATH` | trap path used |
| `PC_START_MS` | run start (epoch ms) — to find the right capture in your logs |
| `PC_IP` | origin IP (check-host only; Globalping doesn't expose probe IPs) |
| `PC_PROBE_COUNTRY`, `PC_PROBE_ASN`, `PC_PROBE_NETWORK` | probe country, ASN and provider |

Generic example — look up the IP captured after `PC_START_MS` in your logs and call your unblock API:

```bash
passport trap-test --host app.example.com --country KZ --canary-text my-canary \
  --on-finish ./examples/generic-unblock.sh
```

See [`examples/generic-unblock.sh`](examples/generic-unblock.sh).

## How it works

- **Globalping** — `POST https://api.globalping.io/v1/measurements` with `type: http`, `locations: [{country, tags:["datacenter-network"]}]` and the path in `measurementOptions.request.path`; then `GET /v1/measurements/{id}` until it finishes. To repeat the same probe, `locations` becomes the previous measurement id.
- **check-host.net** — `GET https://check-host.net/check-http?host=URL&node=NODE` and `GET /check-result/{id}`; the node list comes from `/nodes/hosts`.
- `passport` sends its own `User-Agent` to the APIs; the request to your site carries each network's User-Agent (`CheckHost (https://check-host.net/)` on check-host).

## Limits and gotchas

- **Globalping rejects sensitive paths** such as `/.env` and `/.git/config` ("not allowed for security reasons") — that's their anti-abuse guard. That's why the default bait on Globalping is `/wp-login.php`. For `/.env`, use `--node` (check-host). The rejection message is shown exactly as the API returns it.
- **Quota**: unauthenticated Globalping allows about 250 measurements per hour per IP. One `trap-test` uses 3.
- **Globalping does not reveal probe IPs** — only country, city, provider and ASN. Find the IP in your protection's logs (see `PC_START_MS`).
- **Timing**: step 2 often takes a few seconds if your trap deliberately delays the response (tarpit) — that's expected.
- **Your VPN/ZTNA doesn't interfere**: requests to the site leave from the probes, not from your machine. Only the canary check (step 1) runs from your machine.

## Responsible use

- **Only test systems you operate or are authorized to test.** `trap-test` requests paths typical of scanners.
- **Prefer development hosts**: the tested URL goes through third-party services and results may stay visible there for a while.
- **Always unblock the test origin.** Globalping residential probes run on **volunteers' computers** — forgetting a block locks a real person out of your site. That's why the default is datacenter probes only; `--residential` exists for when a country has nothing else.
- **Be nice to the services**: no bursts, no load testing. They are free and community-run.

## Development

```bash
bash -n passport
shellcheck -S warning passport examples/*.sh
./passport availability KZ
./passport KZ https://example.com
```

CI (`.github/workflows/ci.yml`) runs `bash -n`, ShellCheck and `--help` on every push. Contributions welcome — see [CONTRIBUTING.md](CONTRIBUTING.md).

## Author

Developed and maintained by **[p0intsec](https://github.com/p0intsec)**.

License: [MIT](LICENSE).
