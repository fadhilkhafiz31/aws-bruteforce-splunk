# 🔐 Built the Lock. Picked the Lock. Then Called the Cops on Myself.

**A hands-on penetration testing and detection lab — built, attacked, and defended by one person.**

> Fadhil Khafiz · Software Engineering Intern · Cybersecurity Side Project 2026

---

## What This Project Is

This is not a CTF writeup. This is not a tutorial I followed.

I designed a vulnerable banking application from scratch, deployed it to the cloud, attacked it using real tools, and built the detection layers that caught every attack. Each episode adds a new attack technique or a new defense layer — documented for anyone who wants to understand what actually happens during a security incident.

**Target audience for this repo:** SOC Analyst and Cloud Security Analyst recruiters, hiring managers, and anyone evaluating hands-on security work.

---

## Project Status

| Episode | Type | Focus | Status |
|---------|------|-------|--------|
| Episode 1 | ⚙️ Setup | Build vulnerable OAuth2 server | ✅ Done |
| Episode 2 | 🔴 Attack + 🔵 Defense | Credential stuffing + Splunk detection | ✅ Done |
| Episode 3 | 🔴 Attack | JWT token hijacking + replay | ✅ Done |
| Episode 4 | 🔵 Defense | Automated Splunk alerting | ✅ Done |
| Episode 5 | ⚙️ Setup + 🔴 Attack | AWS EC2 deploy + cloud attack simulation | ✅ Done |
| Episode 6 | 🔵 Defense | Raw Linux log analysis | 🔄 In Progress |
| Episode 7 | ⚙️ Setup | Azure Active Directory setup | ⬜ Upcoming |
| Episode 8 | 🔴 Attack | Password spray against Azure AD | ⬜ Upcoming |

---

## Tech Stack

| Layer | Tools |
|-------|-------|
| Target Application | Node.js, Express, Passport.js, oauth2orize, bcrypt |
| Attack Simulation | Burp Suite, Python (custom scripts), Kali Linux |
| SIEM / Detection | Splunk Enterprise (SPL), Microsoft Sentinel (KQL) |
| Cloud Infrastructure | AWS EC2, AWS GuardDuty, CloudWatch Log Analytics |
| Identity & Access | Azure Entra ID (Active Directory) |
| Database | MySQL |
| Reverse Proxy | Caddy |
| Lab Environment | VirtualBox, Kali Linux |

---

## Episode 1 — Building the Lock

**Type:** ⚙️ Setup | **Difficulty:** ⭐ Beginner

### What I built
A deliberately vulnerable OAuth2 banking server — the target for every attack that follows.

- Node.js + Express REST API with `/login` and `/token` endpoints
- Passport.js with LocalStrategy and BearerStrategy
- oauth2orize authorization code grant flow
- bcrypt password hashing (work factor: 10, with salt)

### Why bcrypt with salt matters
Without salt, two users with the same password produce identical hashes. An attacker with a pre-computed rainbow table can crack thousands of passwords instantly. bcrypt adds a unique random salt before hashing, making every hash unique even for identical passwords.

```js
const hash = bcrypt.hashSync('admin123', 10);
// Output: $2a$10$bbc.ZA1Pca.Qxv.xmQSXSOIxHFA7STjc3KcNRwvqoTr1OZ2RZkGD.
//                  ^^^ work factor — runs 2^10 = 1024 rounds
```

The `$2a$10$` prefix encodes the algorithm, version, and cost factor directly in the hash.

---

## Episode 2 — Picking the Lock + Calling the Cops

**Type:** 🔴 Attack + 🔵 Defense | **Difficulty:** ⭐ Beginner

### Attack: Credential Stuffing with Burp Suite

1. Captured a `POST /login` request in Burp Proxy
2. Sent to Intruder → Sniper mode, payload position on `password` field
3. Loaded a 30-entry wordlist
4. Fired 30 requests — 29 returned `401`, 1 returned `200`
5. **Payload 27 — `admin123` — cracked**

### Detection: Splunk SIEM

Security events written to `security.log` as structured JSON, ingested into Splunk Enterprise.

**Brute force detection query (5-minute window, threshold 10):**
```spl
index=main sourcetype=_json
| spath event_type | spath src_ip
| search event_type="LOGIN_FAILED"
| bucket _time span=5m
| stats count by src_ip, _time
| where count >= 10
```

**Dashboard built (5 panels):**

| Panel | Chart Type |
|-------|-----------|
| Top Attacking IPs | Bar Chart |
| Attack Timeline | Line Chart |
| Targeted Usernames | Bar Chart |
| Failed vs Success Ratio | Pie Chart |
| Threat Correlation | Table |

**Results:** 137 LOGIN_FAILED events from a single IP, clearly spiked on the timeline, all targeting the `admin` account.

---

## Episode 3 — The Key Was Already in the Door

**Type:** 🔴 Attack | **Difficulty:** ⭐ Beginner-Intermediate

### Attack: JWT Token Hijacking + Replay

After a legitimate login, the Bearer token was stolen and replayed from a different IP to impersonate the authenticated user — without ever knowing the password.

```python
import requests
headers = {'Authorization': f'Bearer {stolen_token}'}
r = requests.get('http://localhost:3000/me', headers=headers)
print(r.json())
```

**Detection:** Splunk alert on token reuse from a different source IP than the original session.

---

## Episode 4 — Teaching the Cop to Call Itself

**Type:** 🔵 Defense | **Difficulty:** ⭐ Beginner-Intermediate

### Defense: Automated Splunk Alerting

- Splunk scheduled alert triggers on brute force and JWT replay thresholds
- Python script auto-parses `security.log` and generates a plain-English incident summary report
- Simulated repeated attacks to validate alert thresholds end-to-end

---

## Episode 5 — Taking SecureBank to the Cloud

**Type:** ⚙️ Setup + 🔴 Attack | **Difficulty:** ⭐⭐ Intermediate

### Infrastructure

Deployed the full application stack to a live AWS EC2 instance — real public IP, real internet exposure.

| Component | Detail |
|-----------|--------|
| Compute | AWS EC2 (t3.micro, Ubuntu) |
| Reverse Proxy | Caddy (automatic HTTPS routing) |
| Database | MySQL — all security events persisted |
| Monitoring | AWS CloudWatch Log Analytics (VPC Flow Logs) |

### Attack: Remote Brute Force from Kali Linux

Launched a concurrent Python credential brute-force framework from a separate Kali Linux VM against the live EC2 public IP.

**Result:**
- 54 total attempts
- Payload 52 — `admin123` — `LOGIN_SUCCESS`
- Every event captured in MySQL in real time:

```
LOGIN_FAILED  × 53  |  src_ip: ::ffff:180.74.71.67  |  timestamps logged
LOGIN_SUCCESS × 1   |  12:34:07.911
```

### Detection: CloudWatch Log Analytics

Queried VPC flow logs to visualize the attack traffic spike:

```
fields @timestamp, srcAddr, dstAddr, dstPort, action
| filter srcAddr = '<attacker_ip>'
| stats count(*) by action, dstPort
| sort @timestamp desc
```

Port 3000 and Port 3500 traffic clearly visible — ACCEPT and REJECT events correlated with the attack window.

---

## Detection Coverage Map

| Attack | Detection Layer | Query / Method |
|--------|----------------|----------------|
| Credential stuffing | Splunk SPL | Bucket + threshold on LOGIN_FAILED |
| JWT token replay | Splunk SPL | IP mismatch on Bearer token reuse |
| Remote brute force (cloud) | MySQL + CloudWatch | VPC flow log spike, DB audit trail |
| Password spray (AD) | Azure Sentinel (upcoming) | KQL — spray pattern detection |

---

## MITRE ATT&CK Coverage (Episodes 1–5)

| Technique ID | Name | Episode |
|-------------|------|---------|
| T1110.001 | Brute Force: Password Guessing | Episode 2 |
| T1528 | Steal Application Access Token (JWT) | Episode 3 |
| T1110.003 | Brute Force: Password Spraying | Episode 8 (upcoming) |
| T1078 | Valid Accounts | Episodes 2, 3, 5 |

---

## Repository Structure

```
authentication-mock-up/
├── server.js              # Node.js OAuth2 server with security event logger
├── attack/
│   ├── bruteforce.py      # Credential stuffing script (Ep 2, 5)
│   └── jwt_replay.py      # JWT token hijack + replay (Ep 3)
├── detection/
│   └── alert_parser.py    # Auto-parse security.log → incident summary (Ep 4)
├── logs/
│   └── security.log       # Structured JSON security events (Splunk input)
├── splunk/
│   └── queries.spl        # All detection SPL queries
└── README.md
```

---

## How to Run

### 1. Install dependencies
```bash
npm install
```

### 2. Start the server
```bash
node server.js
# Runs at http://localhost:3000
```

Demo credentials: `admin` / `admin123`

### 3. Simulate brute force
```bash
python attack/bruteforce.py --target http://localhost:3000 --wordlist wordlist.txt
```

### 4. Ingest logs into Splunk
- Settings → Data Inputs → Files & Directories
- Path: `/path/to/logs/security.log`
- Source type: `_json`

---

## References

- [oauth2orize](https://github.com/jaredhanson/oauth2orize)
- [Passport.js](https://www.passportjs.org/)
- [Splunk SPL Reference](https://docs.splunk.com/Documentation/Splunk/latest/SearchReference)
- [Burp Suite Intruder](https://portswigger.net/burp/documentation/desktop/tools/intruder)
- [MITRE ATT&CK](https://attack.mitre.org/)
- [AWS GuardDuty](https://aws.amazon.com/guardduty/)

---

*Last updated: April 2026 · Maintained by Fadhil Khafiz*