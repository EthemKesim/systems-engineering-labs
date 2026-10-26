# Lab 05 — Routing Troubleshooting

## Incident 01 — IPv4 Forwarding Disabled

### Symptom

Client A could not reach Client B despite having a valid default gateway.

### Failure Injection

```bash
sudo ip netns exec rt-router sysctl -w net.ipv4.ip_forward=0
```

### Investigation

```bash
sudo ip -n rt-a route
sudo ip -n rt-router route
sudo ip netns exec rt-router sysctl net.ipv4.ip_forward
sudo ip netns exec rt-a ping -c 3 -W 1 10.50.2.10
```

### Evidence

- Client A's default route existed.
- Router had connected routes for both subnets.
- IPv4 forwarding was disabled (`0`).
- Ping result: 3 transmitted, 0 received, 100% packet loss.

### Root Cause

The Linux router was configured not to forward IPv4 packets between interfaces.

### Fix

```bash
sudo ip netns exec rt-router sysctl -w net.ipv4.ip_forward=1
```

### Verification

```bash
sudo ip netns exec rt-a ping -c 3 10.50.2.10
```

Result: 3 transmitted, 3 received, 0% packet loss.

---

## Incident 02 — Missing Default Gateway

### Symptom

Client A returned `Network is unreachable` when attempting to communicate with Client B.

### Failure Injection

```bash
sudo ip -n rt-a route del default
```

### Investigation

```bash
sudo ip -n rt-a route
sudo ip netns exec rt-a ping -c 3 -W 1 10.50.2.10
```

### Evidence

The routing table contained only:

```text
10.50.1.0/24 dev ra0 scope link src 10.50.1.10
```

The remote subnet had no matching route.

### Root Cause

Client A did not have a route to the remote network.

### Fix

```bash
sudo ip -n rt-a route add default via 10.50.1.1
```

### Verification

```bash
sudo ip netns exec rt-a ping -c 3 10.50.2.10
```

Result: 3 transmitted, 3 received, 0% packet loss.

---

## Comparison

| Problem | Diagnosis | Recovery |
|---|---|---|
| Forwarding disabled | `sysctl net.ipv4.ip_forward` | Set forwarding to `1` |
| Default gateway missing | `ip route` | Restore default route |

## Key Takeaway

A routing failure and a forwarding failure can produce different symptoms even when the physical or virtual interfaces are healthy.

Investigate the source routing table, gateway configuration, router forwarding state, and connectivity before making changes.
