# SecureBank — Auth Attack & Detection Lab

A self-built OAuth2 banking application, deployed to AWS, attacked with real tooling, and monitored for the attacks. Built end to end by one person to learn how authentication attacks work and how they show up in logs.

> Fadhil Khafiz · Information Security & Assurance · 2026

---

## What This Is

I built a deliberately attackable OAuth2 authentication server from scratch, deployed it to a live AWS EC2 instance, ran credential brute-force attacks against it from Kali Linux, and used AWS CloudWatch and a MySQL audit table to detect and investigate those attacks.

Every security event the app produces is written to two places at once: a JSON log file and a MySQL `security_events` table. That dual-logging design is what makes the detection work.

---

## Project Status

Honest status — only ticked items are actually built and evidenced in this repo.

| Part | Focus | Status |
|------|-------|--------|
| Auth server | OAuth2 server, bcrypt, token store, dual security logging | Built |
| Attack — local | Credential stuffing with Burp Suite / Python | Built |
| Attack — cloud | Remote brute force from Kali against live EC2 | Built (see `/assets`) |
| Detection — cloud | CloudWatch VPC Flow Log analysis + MySQL audit trail | Built (see `/assets`) |
| Token replay logic | IP-mismatch detection coded in `/admin` route | Coded, not yet demonstrated end-to-end |
| Detection — SIEM | Splunk ingestion of `security.log` + brute-force search | Not built yet — in progress |
| Automated alerting | Scheduled alert + incident summary script | Not built yet |
| Azure AD / password spray | Entra ID setup + spray detection | Not planned for this phase |

---

## Tech Stack

Only what is actually used in this repo.

| Layer | Tools |
|-------|-------|
| Auth application | Node.js, Express, Passport.js, oauth2orize, bcryptjs |
| Database | MySQL (mysql2) |
| Attack simulation | Kali Linux, Python, Burp Suite |
| Cloud infrastructure | AWS EC2 (t3.micro, Ubuntu), CloudWatch, VPC Flow Logs |
| Reverse proxy | Caddy |

Planned but not yet integrated: Splunk (SIEM correlation of `security.log`).

---

## The Auth Server (Built)

A working OAuth2 authorization-code-grant server with real security engineering:

- Passport LocalStrategy (login) and BearerStrategy (protected routes)
- bcrypt password hashing (work factor 10) — plaintext passwords never touch the DB
- Access tokens stored in MySQL with `issued_ip` and `created_at` metadata
- Token revocation on logout sets `revoked = 1` instead of deleting — keeps an audit trail
- Role-based access control on `/admin`
- Every security event dual-logged to `logs/security.log` (JSON) and MySQL `security_events`

Endpoints: `/register`, `/login`, `/me`, `/admin`, `/transactions`, `/logout`, plus OAuth2 `/oauth/authorize` and `/oauth/token`.

---

## Attack + Detection in the Cloud (Built)

The app was deployed to a live AWS EC2 instance with a real public IP, then attacked remotely from a separate Kali Linux machine.

**Attack:** A Python brute-force script ran 54 login attempts against the live EC2 public IP. Attempt 52 (`admin123`) returned `LOGIN_SUCCESS`; every other attempt returned `401`.

**Detection — MySQL audit trail:** All 54 attempts landed in the `security_events` table on the EC2 host — 53 `LOGIN_FAILED` and 1 `LOGIN_SUCCESS`, all from the attacker's source IP, with millisecond timestamps.

**Detection — CloudWatch:** VPC Flow Logs were queried in CloudWatch Log Insights to visualise the traffic, breaking down ACCEPT vs REJECT counts by destination port during the attack window.

Screenshots of all of the above are in [`/assets`](./assets):

| File | Shows |
|------|-------|
| `ep5_ec2_instances.png` | Live EC2 instance running |
| `ep5_bankIsley_project.png` | App live on the public IP |
| `ep5_kali_brute_force_attack_hit.png` | Kali brute force, 54 attempts, hit on attempt 52 |
| `ep5_mysql_audit_log.png` | `security_events` table capturing the attack |
| `ep5_cloudwatch_analytics.png` | CloudWatch VPC Flow Log breakdown |

> Note: `logs/security.log` in this repo contains local development traffic (localhost `::1`), not the cloud attack. The cloud attack evidence lives in the EC2 MySQL table, shown in the screenshots above.

---

## Repository Structure

```
authentication-mock-up/
├── server.js           # OAuth2 server + dual security logger
├── auth.js             # Passport strategies (Local + Bearer)
├── db.js               # MySQL access layer
├── attack/
│   ├── attack.py       # Credential stuffing (local)
│   └── attack_ep5.py   # Remote brute force against EC2
├── logs/
│   └── security.log    # JSON security events (local dev traffic)
├── assets/             # Screenshots of the cloud attack + detection
└── README.md
```

---

## How to Run

```bash
npm install
node server.js          # runs at http://localhost:3000
```

Simulate a local attack:

```bash
python attack/attack.py
```

---

## Roadmap (Not Yet Built)

- Ingest `logs/security.log` into Splunk and write a brute-force detection search (threshold on `LOGIN_FAILED` per `src_ip` over a time window)
- Demonstrate the coded token-replay detection end-to-end and capture the `TOKEN_REPLAY_DETECTED` event
- Scheduled alerting + a script that turns raw events into a plain-English incident summary

---

*Maintained by Fadhil Khafiz*