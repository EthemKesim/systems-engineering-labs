# Lab 05 — Linux Routing Between Subnets

## Objective

Build a Linux router connecting two isolated IPv4 subnets. Understand default gateways, routing tables, IP forwarding, and network troubleshooting.

## Network Architecture

```text
rt-a                         rt-router                          rt-b
10.50.1.10/24                10.50.1.1/24                        10.50.2.10/24
    ra0 ─────── rr0 [Linux Router] rr1 ─────── rb0
                               10.50.2.1/24
```

The router connects:

- Network A: `10.50.1.0/24`
- Network B: `10.50.2.0/24`

## Environment

- Ubuntu 26.04 ARM64
- UTM/QEMU
- Linux network namespaces and veth pairs

## 1. Creating the Topology

```bash
sudo ip netns add rt-a
sudo ip netns add rt-router
sudo ip netns add rt-b

sudo ip link add ra0 type veth peer name rr0
sudo ip link add rb0 type veth peer name rr1

sudo ip link set ra0 netns rt-a
sudo ip link set rr0 netns rt-router
sudo ip link set rb0 netns rt-b
sudo ip link set rr1 netns rt-router
```

### Command explanations

- `ip netns add`: Creates an isolated network namespace.
- `ip link add ... type veth`: Creates a connected virtual Ethernet pair.
- `ip link set ... netns`: Moves an interface into a namespace.

## 2. IP Configuration

```bash
sudo ip -n rt-a addr add 10.50.1.10/24 dev ra0
sudo ip -n rt-router addr add 10.50.1.1/24 dev rr0

sudo ip -n rt-b addr add 10.50.2.10/24 dev rb0
sudo ip -n rt-router addr add 10.50.2.1/24 dev rr1
```

All veth interfaces and namespace loopback interfaces were enabled using `ip link set ... up`.

The router has one interface in each subnet.

## 3. Initial Routing Failure

Command:

```bash
sudo ip netns exec rt-a ping -c 3 -W 1 10.50.2.10
```

Observed error:

```text
ping: connect: Network is unreachable
```

Investigation:

```bash
sudo ip -n rt-a route
```

Initially, `rt-a` knew only the directly connected `10.50.1.0/24` network.

## 4. Configuring Default Gateways

```bash
sudo ip -n rt-a route add default via 10.50.1.1
sudo ip -n rt-b route add default via 10.50.2.1
```

### Commands explained

- `route add`: Adds a routing table entry.
- `default`: Route used when no more specific route matches.
- `via`: Specifies the next-hop gateway.

Verification:

```bash
sudo ip -n rt-a route get 10.50.2.10
```

Observed route:

```text
10.50.2.10 via 10.50.1.1 dev ra0 src 10.50.1.10
```

After configuring gateways, cross-subnet ping succeeded because the router already had IP forwarding enabled.

## 5. IP Forwarding

Command:

```bash
sudo ip netns exec rt-router sysctl net.ipv4.ip_forward
```

Observed initial value:

```text
net.ipv4.ip_forward = 1
```

`1` means IPv4 forwarding is enabled; `0` means it is disabled.

We subsequently disabled forwarding deliberately to investigate the effect on routed connectivity.

## 6. Connectivity Verification

Tests:

```bash
sudo ip netns exec rt-a ping -c 3 10.50.2.10
sudo ip netns exec rt-b ping -c 3 10.50.1.10
```

Both directions passed with 3/3 packets received.

Observed reply TTL: `63`, consistent with a routed hop.

## 7. Troubleshooting

Two controlled incidents were reproduced:

1. IPv4 forwarding disabled on the router, causing 100% packet loss.
2. Default gateway deleted from Client A, causing `Network is unreachable`.

Both were diagnosed and recovered successfully.

Detailed commands and evidence are available in [troubleshooting.md](troubleshooting.md).

## Cloud & DevOps Connections

- AWS VPC route tables and gateways
- Linux-based routers and container networking
- Kubernetes node routing and CNI fundamentals
- Packet forwarding troubleshooting
- Network connectivity incident investigation

## Lessons Learned

- Different subnets require a suitable routing path.
- A client needs a route to reach remote destinations.
- A Linux router must permit IP forwarding.
- Correct routes do not guarantee forwarding is enabled.
- Diagnose both the source host and the intermediate router.
- Repeat the original failing test to verify recovery.

## Next Steps

- Misconfigured next-hop routing
- NAT and masquerading
- Linux firewall rules
- Packet inspection with tcpdump
