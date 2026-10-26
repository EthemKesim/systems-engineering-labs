# Lab 04 — Troubleshooting & Recovery

## Method

Each incident follows the same workflow:

**Symptom → Investigation → Root Cause → Fix → Verification**

All incidents were reproduced in an isolated Ubuntu networking lab.

## Incident 01 — Bridge Port Disabled

**Symptom:** `ns1` could not ping `10.10.10.13`.

**Failure injection:**

```bash
sudo ip link set veth-br3 down
```

**Investigation:**

```bash
ip -br link show veth-br3
bridge link show
sudo ip netns exec ns1 ip neigh show
```

**Evidence:**

- `veth-br3` was `DOWN`.
- The bridge port reported `state disabled`.
- The neighbor entry for `10.10.10.13` became `FAILED`.
- Ping: 3 transmitted, 0 received.

**Root cause:** The bridge-side virtual Ethernet interface was disabled.

**Fix:**

```bash
sudo ip link set veth-br3 up
```

**Verification:**

```bash
sudo ip netns exec ns1 ping -c 3 10.10.10.13
```

Result: 3/3 packets received, 0% packet loss.

---

## Incident 02 — Interface Detached From Bridge

**Symptom:** `ns1` could no longer reach `ns2`, despite `veth-br2` remaining `UP`.

**Failure injection:**

```bash
sudo ip link set veth-br2 nomaster
```

**Investigation:**

```bash
ip -br link show veth-br2
bridge link show
sudo ip netns exec ns1 ip neigh show
```

**Evidence:**

- `veth-br2` remained `UP`.
- `veth-br2` disappeared from the bridge member list.
- Neighbor resolution for `10.10.10.12` failed.
- ns1-to-ns2 ping: 100% packet loss.
- ns1-to-ns3 ping: 0% packet loss.

**Root cause:** The interface no longer belonged to `br-lab`.

**Fix:**

```bash
sudo ip link set veth-br2 master br-lab
sudo ip link set veth-br2 up
```

**Verification:**

```bash
sudo ip netns exec ns1 ping -c 3 10.10.10.12
bridge link show
```

Result: 3/3 packets received; all three bridge ports reported `state forwarding`.

---

## Incident 03 — Incorrect IPv4 Subnet

**Symptom:** A network namespace could not reach the changed ns3 IP address.

**Failure injection:**

```bash
sudo ip netns exec ns3 ip addr del 10.10.10.13/24 dev veth-ns3
sudo ip netns exec ns3 ip addr add 10.10.20.13/24 dev veth-ns3
```

**Investigation:**

```bash
sudo ip netns exec ns1 ping -c 3 -W 1 10.10.20.13
sudo ip netns exec ns1 ip route
sudo ip netns exec ns3 ip route
```

**Evidence:**

```text
ping: connect: Network is unreachable
```

Observed connected routes:

```text
ns1: 10.10.10.0/24 via veth-ns1
ns3: 10.10.20.0/24 via veth-ns3
```

**Root cause:** The namespace addresses were in different subnets, with no route configured between them.

**Fix:**

```bash
sudo ip netns exec ns3 ip addr del 10.10.20.13/24 dev veth-ns3
sudo ip netns exec ns3 ip addr add 10.10.10.13/24 dev veth-ns3
```

**Verification:**

```bash
sudo ip netns exec ns1 ping -c 3 10.10.10.13
```

Result: 3/3 packets received, 0% packet loss.

---

## Troubleshooting Reference

| Observation | Likely investigation |
|---|---|
| Interface `DOWN` | Check administrative/link state |
| Bridge port missing | Check bridge membership |
| Neighbor `FAILED` | Check Layer 2 path and ARP |
| `Network is unreachable` | Check route table and subnet |
| 100% packet loss | Check interfaces, ARP, routing, and filtering |

## Lessons Learned

A successful diagnosis depends on checking each networking layer separately. Service or interface status alone is insufficient.

The best recovery approach is to identify the exact broken component, make the smallest necessary correction, and repeat the original test.
