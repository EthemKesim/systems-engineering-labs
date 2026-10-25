# Lab 03 — Linux Network Namespaces & veth

## Objective

Build an isolated virtual network using Linux network namespaces and a virtual Ethernet (veth) pair. Practice IP addressing, routing, connectivity testing, controlled failures, and recovery.

## Environment

- Ubuntu 26.04 LTS ARM64
- UTM / QEMU
- Hostname: `lab-ubuntu`
- Tools: `iproute2`, `ping`

## Network Architecture

```text
+-----------------------+       +-----------------------+
| Namespace: ns-a       |       | Namespace: ns-b       |
|                       |       |                       |
| veth-a                |=======| veth-b                |
| 10.200.1.1/24         | veth  | 10.200.1.2/24         |
+-----------------------+       +-----------------------+
```

Both interfaces belong to the `10.200.1.0/24` subnet and can communicate without a router.

## 1. Creating Network Namespaces

```bash
sudo ip netns add ns-a
sudo ip netns add ns-b
ip netns list
```

**Commands explained:**

- `sudo`: Runs the command with administrative privileges.
- `ip netns add`: Creates a named Linux network namespace.
- `ip netns list`: Lists existing named network namespaces.

A network namespace provides an isolated network environment with its own interfaces, IP addresses, routing table, and port space.

## 2. Creating a veth Pair

```bash
sudo ip link add veth-a type veth peer name veth-b
sudo ip link set veth-a netns ns-a
sudo ip link set veth-b netns ns-b
```

**Commands explained:**

- `ip link add`: Creates a network interface.
- `type veth`: Creates a virtual Ethernet pair.
- `peer name`: Assigns a name to the other end.
- `ip link set ... netns`: Moves an interface into a network namespace.

A veth pair behaves like a virtual network cable: packets sent through one end can be received at the other.

## 3. Assigning IP Addresses

```bash
sudo ip netns exec ns-a ip addr add 10.200.1.1/24 dev veth-a
sudo ip netns exec ns-b ip addr add 10.200.1.2/24 dev veth-b

sudo ip netns exec ns-a ip link set lo up
sudo ip netns exec ns-b ip link set lo up

sudo ip netns exec ns-a ip link set veth-a up
sudo ip netns exec ns-b ip link set veth-b up
```

**Commands explained:**

- `ip netns exec`: Executes a command in a namespace's network context.
- `ip addr add`: Assigns an IP address to an interface.
- `/24`: Uses a 24-bit network prefix.
- `ip link set ... up`: Administratively enables an interface.
- `lo`: Loopback interface inside the namespace.

## 4. Connectivity Verification

```bash
sudo ip netns exec ns-a ping -c 4 10.200.1.2
sudo ip netns exec ns-b ping -c 4 10.200.1.1
```

**Results:**

| Direction | Packets Received | Packet Loss |
|---|---:|---:|
| ns-a → ns-b | 4/4 | 0% |
| ns-b → ns-a | 4/4 | 0% |

Both directions had approximately 0.116 ms average round-trip time in the initial test.

## 5. Inspecting Routing Tables

```bash
sudo ip netns exec ns-a ip route
sudo ip netns exec ns-b ip route
```

Observed routes:

```text
ns-a: 10.200.1.0/24 dev veth-a scope link src 10.200.1.1
ns-b: 10.200.1.0/24 dev veth-b scope link src 10.200.1.2
```

**Explanation:**

- `10.200.1.0/24`: Directly connected subnet.
- `dev`: Outgoing network interface.
- `scope link`: Destination network is directly reachable through the link.
- `src`: Preferred source address.

No default gateway was required for communication between these two interfaces.

## 6. Failure Injection — Interface DOWN

```bash
sudo ip netns exec ns-a ip link set veth-a down
sudo ip netns exec ns-a ping -c 3 -W 1 10.200.1.2
```

**Observed result:**

```text
ping: connect: Network is unreachable
```

The connected route was no longer available while the interface was down.

**Recovery:**

```bash
sudo ip netns exec ns-a ip link set veth-a up
sudo ip netns exec ns-a ping -c 3 10.200.1.2
```

Result: 3/3 packets received.

## 7. Failure Injection — Subnet Mismatch

Changed the second namespace's IP address:

```bash
sudo ip netns exec ns-b ip addr del 10.200.1.2/24 dev veth-b
sudo ip netns exec ns-b ip addr add 10.200.2.2/24 dev veth-b
```

The two namespaces were now configured in different subnets.

A ping from `ns-a` to `10.200.2.2` failed with:

```text
ping: connect: Network is unreachable
```

`ns-a` had a route for `10.200.1.0/24`, but no route for `10.200.2.0/24`.

**Recovery:**

```bash
sudo ip netns exec ns-b ip addr del 10.200.2.2/24 dev veth-b
sudo ip netns exec ns-b ip addr add 10.200.1.2/24 dev veth-b
```

Result: 3/3 packets received after restoring the original subnet.

## 8. Challenge 04 — Network Recovery

Disabled the second veth interface:

```bash
sudo ip netns exec ns-b ip link set veth-b down
sudo ip netns exec ns-a ping -c 3 -W 1 10.200.1.2
```

**Observed result:** 100% packet loss.

Restored connectivity:

```bash
sudo ip netns exec ns-b ip link set veth-b up
```

Verified communication in both directions.

| Direction | Packets Received | Packet Loss |
|---|---:|---:|
| ns-a → ns-b | 3/3 | 0% |
| ns-b → ns-a | 3/3 | 0% |

## 9. Troubleshooting Lessons

- An administratively disabled interface cannot provide normal network connectivity.
- Correct IP addressing is not sufficient without an appropriate route.
- `Network is unreachable` and packet loss are different troubleshooting symptoms.
- A connected route can disappear when its interface goes down.
- Always verify recovery by repeating the original failing test.
- Existing namespaces cannot be recreated with the same names until they have been removed.

## 10. Cloud & DevOps Connections

These experiments provide foundational knowledge for:

- Docker container network isolation
- Virtual Ethernet interfaces used in container networking
- Linux bridges and container connectivity
- Kubernetes Pod networking
- Routing and network troubleshooting
- Diagnosing infrastructure connectivity incidents

## Next Steps

- Connect multiple namespaces through a Linux bridge.
- Inspect ARP and neighbor discovery.
- Practice routing between separate subnets.
- Explore NAT, firewall rules, and packet capture.
