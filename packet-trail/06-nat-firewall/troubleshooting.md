# Lab 06 — Incidents, Diagnosis & Recovery

## Method

For each scenario: **Build → Break → Observe → Diagnose → Fix → Verify**. These cases were performed using `rt-a`, `rt-router` and `rt-b`. Only rules in the dedicated `packettrail` / `packettrail_nat` tables were created or deleted.

## Incident 01 — ICMP blocked by firewall

**Symptom:** `rt-a` could not ping `rt-b` (3 sent, 0 received); reverse direction still succeeded (3/3).

**Introduced with:**

```bash
sudo ip netns exec rt-router nft add table inet packettrail
sudo ip netns exec rt-router nft 'add chain inet packettrail forward { type filter hook forward priority 0; policy accept; }'
sudo ip netns exec rt-router nft add rule inet packettrail forward \
  iifname "rr0" oifname "rr1" ip saddr 10.50.1.10 ip daddr 10.50.2.10 \
  ip protocol icmp icmp type echo-request counter drop
```

**Diagnosis:**

```bash
sudo ip netns exec rt-router nft -a list table inet packettrail
sudo ip netns exec rt-router tcpdump -ni rr0 -c 3 \
  'icmp and src host 10.50.1.10 and dst host 10.50.2.10'
```

**Evidence:** `counter packets 3 bytes 252 drop`; incoming router interface observed three Echo Requests. Routing had been working before the new rule.

**Root cause:** Selected ICMP Echo Requests matched the forwarding chain's `drop` rule.

**Fix:**

```bash
sudo ip netns exec rt-router nft delete table inet packettrail
```

**Verification:** both directions again completed 3/3 ping. The original fault was a firewall filter, not a missing route.

## Incident 02 — Source IP changed by explicit SNAT

**Goal:** Determine why a remote host sees `10.50.2.1` instead of the client's `10.50.1.10`.

**Diagnosis:** `tcpdump -ni rb0` in `rt-b` first observed `10.50.1.10 > 10.50.2.10`, then after the rule observed `10.50.2.1 > 10.50.2.10`.

**Rule:**

```bash
sudo ip netns exec rt-router nft add rule ip packettrail_nat postrouting \
  ip saddr 10.50.1.10 ip daddr 10.50.2.10 oifname "rr1" snat to 10.50.2.1
```

**Root cause of the address change:** Intended source translation in the router's postrouting hook.

**Recovery:** Remove the dedicated `ip packettrail_nat` table if it exists; start a new ping flow and recapture the source IP. In a later verification attempt the table had already disappeared; the successful ping in that later attempt is not counted as an SNAT-active connectivity test.

## Incident 03 — Missing namespace after VM restart

**Symptom:** `Cannot open network namespace "rt-router": No such file or directory`.

**Diagnosis:**

```bash
ip netns list
uptime -s
```

The namespace list was empty. This is consistent with a VM restart: manually created namespace configurations are ephemeral. The exact deletion cause was not independently recorded.

**Fix:** Recreate the lab safely:

```bash
cd ~/packettrail-lab06
sudo bash setup.sh
```

**Verification:** script completed, IPv4 forwarding was `1`, and both directions passed 2/2 ping.

**Prevention:** Keep a repeatable setup script and a restricted cleanup script. Do not rely on namespace state surviving a reboot.

## Incident 04 — MASQUERADE rewrites the source IP

**Goal:** Observe dynamic source address selection via the router's output interface.

**Rule:**

```bash
sudo ip netns exec rt-router nft add rule ip packettrail_nat postrouting \
  ip saddr 10.50.1.10 ip daddr 10.50.2.10 oifname "rr1" masquerade
```

**Diagnosis:**

```bash
sudo ip netns exec rt-router nft list table ip packettrail_nat
sudo ip netns exec rt-b tcpdump -ni rb0 -c 3 \
  'icmp and src host 10.50.2.1 and dst host 10.50.2.10'
```

**Evidence:** three captured requests from translated address `10.50.2.1`, ICMP IDs 4587 and sequence numbers 1–3; NAT-active ping returned 3/3.

**Fix / restore normal state:**

```bash
sudo ip netns exec rt-router nft delete table ip packettrail_nat
sudo ip netns exec rt-router nft list ruleset
sudo ip netns exec rt-a ping -c 3 10.50.2.10
```

**Verification:** the displayed ruleset was empty and 3/3 pings succeeded after NAT removal.

## Diagnostic shortcuts

| Symptom | Check | Interpretation |
|---|---|---|
| `Network is unreachable` | `ip -n rt-a route` | Missing route / gateway likely |
| Ping loss but routes exist | `nft list ruleset` | Filtering may drop transit packets |
| Incoming packet visible but not delivered | `tcpdump` on ingress + egress | Locate the dropping/rewriting stage |
| Unexpected source IP | `tcpdump` on destination and `nft list` | Verify SNAT/masquerade |
| Namespace missing | `ip netns list` | Recreate ephemeral topology after verifying absence |

`tcpdump` is observation, not policy. `nft` expresses firewall/NAT policy. Counters and before/after tests provide evidence for root-cause claims.
