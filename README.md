# SecureBank — Auth Attack & Detection Lab

A self-built OAuth2 banking application, deployed to AWS, attacked with real tooling, and monitored end to end — from the application logs and cloud network layer through to SIEM detection in Splunk. Built by one person to learn how authentication attacks work and how they surface across a detection stack.

> Fadhil Khafiz · Information Security & Assurance · 2026

---

## What This Is

I built a deliberately attackable OAuth2 authentication server, deployed it to a live AWS EC2 instance behind Caddy, ran a credential brute force against it from Kali Linux, and detected the attack across three layers: the application's own audit log (MySQL), the cloud network layer (CloudWatch VPC Flow Logs), and a SIEM (Splunk) ingesting the app's security events.

Every security event is written to two places at once — a JSON log file and a MySQL `security_events` table. The file feeds Splunk; the table is a directly queryable audit trail. The events are enriched with SOC-style fields (`event_id`, `severity`, `user_agent`) so they correlate the way real SIEM data does.

---

## Detection Stack

| Layer | Tool | What it catches |
|-------|------|-----------------|
| Application audit trail | MySQL (`security_events`) | Every auth event, queryable with SQL |
| Cloud network | AWS CloudWatch (VPC Flow Logs) | Traffic spike from the attacker IP by port/action |
| SIEM | Splunk (SPL) | Brute force detection, attack-lifecycle correlation, token replay |

---

## The Attack (Real, Cloud)

Deployed the app to a live EC2 instance (t3.micro, Ubuntu, `ap-southeast-2`) fronted by Caddy on port 80. From a separate Kali Linux machine, ran a Python credential brute force against the public IP.

- **Attacker IP:** `180.74.71.5` (real Kali source, captured correctly through Caddy via `X-Forwarded-For`)
- **53 failed logins** plus successful logins, all recorded with millisecond timestamps
- Attack tool signature visible in the logs: `python-requests` user-agent

The same attacker IP appears consistently across all three detection layers — Kali, MySQL, and CloudWatch — which is what makes the evidence corroborate rather than conflict.

## Token Replay (Simulated, Single-Host)

Separately demonstrated session-token replay detection. A valid token issued at one IP is reused from a different IP (`203.0.113.77`, TEST-NET-3 documentation range, supplied via `X-Forwarded-For`). The app's `/admin` route compares the token's `issued_ip` against the request IP and flags the mismatch as `TOKEN_REPLAY_DETECTED` (severity: high).

This is a single-host simulation — the second IP is spoofed via a trusted-loopback `X-Forwarded-For` header, not a second physical machine. It demonstrates the *detection* of token reuse, which does not depend on how the token was obtained.

---

## SIEM Detection in Splunk

The enriched `security.log` from the cloud attack was ingested into Splunk (`sourcetype=_json`) and queried with the searches in [`splunk/queries.spl`](./splunk/queries.spl).

**Brute force detection** — failed logins per source IP in 5-minute windows, thresholded. Surfaces `180.74.71.5` with 53 failed attempts against the `admin` account from a `python-requests` client.

**Attack-lifecycle correlation** — one row per source IP summarising failed logins, successes, admin access, and replay alerts. Cleanly separates the brute-force IP (`180.74.71.5`) from the replay event (`203.0.113.77`).

**Token replay** — isolates the `TOKEN_REPLAY_DETECTED` event, showing `issued_ip` vs `src_ip` and the `token_used_from_different_ip` reason.

Screenshots of all detection layers are in [`/assets`](./assets).

---
## MITRE ATT&CK Mapping

Every attack step in this lab maps to a documented ATT&CK technique, and each detection is written against that technique — the same way MDR playbooks are structured.

| Attack step | ATT&CK Technique | Detected by | Detection logic |
|-------------|------------------|-------------|-----------------|
| Credential brute force against `/login` | [T1110.001 — Brute Force: Password Guessing](https://attack.mitre.org/techniques/T1110/001/) | Splunk SPL, MySQL audit, CloudWatch | Failed logins per source IP in 5-min windows, thresholded; corroborated by VPC Flow Log traffic spike |
| Login with compromised credentials | [T1078 — Valid Accounts](https://attack.mitre.org/techniques/T1078/) | Splunk SPL (lifecycle correlation) | Success event from same source IP immediately following failure burst |
| Session token reuse from a different IP | [T1550.001 — Use Alternate Authentication Material: Application Access Token](https://attack.mitre.org/techniques/T1550/001/) | Application logic + Splunk SPL | `issued_ip` vs `src_ip` mismatch on protected route → `TOKEN_REPLAY_DETECTED` (high severity) |
| Attack tooling fingerprint | — (enrichment, not a technique) | Splunk SPL | `python-requests` user-agent flags non-browser automation |

--

## The Auth Server

A working OAuth2 authorization-code-grant server:

- Passport LocalStrategy (login) and BearerStrategy (protected routes)
- bcrypt password hashing (work factor 10)
- Access tokens stored in MySQL with `issued_ip` metadata (enables the replay check)
- Token revocation on logout keeps an audit trail (`revoked = 1`, not deleted)
- Role-based access control on `/admin`
- Dual security logging (JSON file + MySQL), enriched with `event_id`, `severity`, `user_agent`

Endpoints: `/register`, `/login`, `/me`, `/admin`, `/transactions`, `/logout`, plus OAuth2 `/oauth/authorize` and `/oauth/token`.

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| Auth application | Node.js, Express, Passport.js, oauth2orize, bcryptjs |
| Database | MySQL (mysql2) |
| Attack simulation | Kali Linux, Python |
| Cloud infrastructure | AWS EC2, CloudWatch, VPC Flow Logs |
| Reverse proxy | Caddy |
| SIEM | Splunk (SPL) |

---

## Repository Structure

```
authentication-mock-up/
├── server.js              # OAuth2 server + enriched dual security logger
├── auth.js                # Passport strategies (Local + Bearer)
├── db.js                  # MySQL access layer
├── attack/
│   ├── attack.py          # Credential brute force
│   └── postexploit.py     # Post-compromise chain + token replay
├── splunk/
│   └── queries.spl        # SIEM detection & correlation searches
├── logs/
│   └── security.log       # JSON security events (gitignored in practice)
├── assets/                # Screenshots: attack, MySQL, CloudWatch, Splunk
└── README.md
```

---

## How to Run

```bash
npm install
node server.js          # http://localhost:3000

python attack/attack.py            # brute force
python attack/postexploit.py       # post-compromise + replay
```

Ingest `logs/security.log` into Splunk as `sourcetype=_json`, then run the searches in `splunk/queries.spl`.

---

*Maintained by Fadhil Khafiz*