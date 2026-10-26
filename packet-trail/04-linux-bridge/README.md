# Lab 04 — Linux Bridge & Switching

## Objective

Build a virtual Layer 2 network connecting three Linux network namespaces through a Linux bridge. Learn switching, ARP, MAC address learning, and evidence-based network troubleshooting.

## Environment

- Ubuntu 26.04 LTS ARM64 on UTM/QEMU
- Linux network namespaces: `ns1`, `ns2`, `ns3`
- Linux bridge: `br-lab`
- Tools: `iproute2`, `bridge`, `ping`

## Network Architecture

```text
ns1 (10.10.10.11/24) -- veth-br1 --+
                                    |
ns2 (10.10.10.12/24) -- veth-br2 --+-- br-lab (Linux Bridge)
                                    |
ns3 (10.10.10.13/24) -- veth-br3 --+
```

Each namespace has a dedicated veth pair. The host-side interfaces connect to `br-lab`.

All three namespaces share the `10.10.10.0/24` subnet.

## Commands Explained

| Command | Purpose |
|---|---|
| `ip netns add ns1` | Create an isolated network namespace |
| `ip link add br-lab type bridge` | Create a Linux Layer 2 bridge |
| `ip link add ... type veth peer name ...` | Create two connected virtual Ethernet interfaces |
| `ip link set ... netns ns1` | Move an interface into a namespace |
| `ip link set ... master br-lab` | Attach an interface to the bridge |
| `ip link set ... up` | Administratively enable an interface |
| `ip addr add ... dev ...` | Assign an IP address to an interface |
| `bridge link show` | Inspect bridge member ports and their states |
| `ip neigh show` | Inspect IP-to-MAC neighbor resolution |
| `bridge fdb show br br-lab` | Inspect MAC-to-bridge-port forwarding information |
| `ping -c 3` | Send three ICMP Echo Requests |

## Connectivity Verification

Initial tests:

| Source | Destination | Result |
|---|---|---|
| ns1 | 10.10.10.12 | 3/3 received |
| ns1 | 10.10.10.13 | 3/3 received |
| ns2 | 10.10.10.13 | 3/3 received |

All tests completed with 0% packet loss.

## ARP and Bridge FDB

The `ns1` neighbor table contained:

```text
10.10.10.12 -> 9e:d4:08:d6:97:71
10.10.10.13 -> 16:b3:33:b8:65:b9
```

The bridge FDB associated these MAC addresses with `veth-br2` and `veth-br3`, respectively.

**ARP** maps an IPv4 address to a MAC address on the local link.

**FDB** maps learned MAC addresses to bridge ports.

The bridge forwards Ethernet frames at Layer 2. A router is not required when communicating within this directly connected subnet.

## Failure Injection Results

Three controlled incidents were tested:

1. Disabled bridge port `veth-br3`: ns1-to-ns3 traffic experienced 100% packet loss.
2. Detached `veth-br2` from `br-lab`: ns1-to-ns2 communication failed, while ns1-to-ns3 continued working.
3. Changed ns3 to `10.10.20.13/24`: ns1 reported `Network is unreachable` because no route existed to that subnet.

All three incidents were recovered successfully and verified with repeat ping tests.

For investigation commands and recovery steps, see [troubleshooting.md](troubleshooting.md).

## Cloud & DevOps Relevance

- Docker bridge networking and virtual Ethernet devices
- Container connectivity troubleshooting
- Layer 2 switching and MAC learning
- Diagnosing incorrect interfaces, routes, and IP addresses
- Foundation for Kubernetes Pod connectivity and CNI networking

## Key Lessons

- An interface can be `UP` without belonging to the correct bridge.
- A failed neighbor entry can indicate a Layer 2 connectivity issue.
- Correct bridge membership does not guarantee correct Layer 3 addressing.
- Compare healthy and failing paths before changing configuration.
- Every recovery should be verified with the original failing test.

## Next Lab

Lab 05 — Routing Between Subnets: IP forwarding, gateways, route tables, controlled routing failures, and recovery.
