# Lab 06 — NAT, nftables & Packet Analysis

## Objective
Build a reproducible two-subnet Linux network and use evidence from `nft` and `tcpdump` to explain packet filtering and source NAT. The environment is restricted to three named network namespaces; host/Docker firewall rules are not modified.

## Architecture

```text
rt-a                 rt-router                      rt-b
10.50.1.10/24        rr0 10.50.1.1/24               10.50.2.10/24
     ra0 ----------  [  IPv4 forwarding ]  -------- rb0
                     rr1 10.50.2.1/24

route in rt-a: default via 10.50.1.1
route in rt-b: default via 10.50.2.1
```

The router has a directly connected route for both /24 subnets. The clients use the router as their default gateway.

## Reproduce and tear down

Run on Ubuntu with root privileges; `iproute2`, `ping`, and `sysctl` are required:

```bash
sudo bash setup.sh
sudo bash cleanup.sh           # inspect only / dry run
sudo bash cleanup.sh --delete  # remove only verified lab namespaces
```

`setup.sh` refuses to modify an existing lab with the same names. `cleanup.sh` checks expected addresses and interface names before deleting. Do not use these names for unrelated resources. Setup may be rerun after a VM reboot, when ephemeral namespaces disappear.

## Main commands explained

| Command or syntax | Purpose |
|---|---|
| `ip netns add NAME` | Create a named network namespace. |
| `ip link add A type veth peer name B` | Create an Ethernet pair; packets exit one end at the other. |
| `ip link set IFACE netns NAME` | Move an interface into a namespace. |
| `ip -n NAME addr add IP/PREFIX dev IFACE` | Assign an interface address inside a namespace. |
| `ip -n NAME route add default via GATEWAY` | Set the fallback next hop for remote networks. |
| `ip netns exec NAME sysctl -w net.ipv4.ip_forward=1` | Allow IPv4 forwarding in the router namespace. |
| `nft add table ip TABLE` | Create an IPv4 nftables table. |
| `nft add table inet TABLE` | Create a table usable for IPv4 and IPv6 rules. |
| `hook forward` | Examine packets transiting this router. |
| `hook postrouting priority srcnat` | Apply source-address changes after a route is chosen. |
| `counter drop` | Count matching packets and discard them. |
| `snat to ADDRESS` | Rewrite the source IP to an explicitly chosen address. |
| `masquerade` | Rewrite the source IP using the outgoing interface address. |
| `nft list ruleset` | Show installed nftables configuration. |
| `tcpdump -ni IFACE -c 3 'FILTER'` | Capture three matching packets without hostname lookup. |
| `ping -c 3 -W 1 IP` | Send three ICMP Echo Requests with a one-second reply wait. |

## Experiment 1 — Baseline

Tools were present: `/usr/sbin/nft`, `/usr/bin/tcpdump`, `/usr/sbin/ip`. Router forwarding was `1`; the router nftables ruleset was empty. Pings succeeded both ways (3/3 in each direction).

## Experiment 2 — Selective firewall drop

Created a lab-specific nftables table and `forward` chain:

```bash
sudo ip netns exec rt-router nft add table inet packettrail
sudo ip netns exec rt-router nft 'add chain inet packettrail forward { type filter hook forward priority 0; policy accept; }'
sudo ip netns exec rt-router nft add rule inet packettrail forward \
  iifname "rr0" oifname "rr1" \
  ip saddr 10.50.1.10 ip daddr 10.50.2.10 \
  ip protocol icmp icmp type echo-request counter drop
```

- `rt-a -> rt-b`: 3 sent, 0 received (100% packet loss).
- `rt-b -> rt-a`: 3 sent, 3 received (0% loss).
- nftables counter: **3 packets, 252 bytes** dropped after initial test.
- `tcpdump` on incoming router interface `rr0`: **3 ICMP Echo Requests** observed.

Restored connectivity by deleting only `inet packettrail` and verified 3/3 in both directions.

## Experiment 3 — Explicit SNAT

```bash
sudo ip netns exec rt-router nft add table ip packettrail_nat
sudo ip netns exec rt-router nft 'add chain ip packettrail_nat postrouting { type nat hook postrouting priority srcnat; policy accept; }'
sudo ip netns exec rt-router nft add rule ip packettrail_nat postrouting \
  ip saddr 10.50.1.10 ip daddr 10.50.2.10 oifname "rr1" snat to 10.50.2.1
```

`tcpdump` on `rt-b/rb0` showed the original source `10.50.1.10` before NAT and **translated source `10.50.2.1`** with SNAT. In a later test, the NAT table was absent, so that later successful ping is not evidence of SNAT-active connectivity; document the observed state rather than assuming the rule still existed.

## Experiment 4 — MASQUERADE

After restoring the namespace topology with `setup.sh`, created a new NAT table and installed a masquerade rule:

```bash
sudo ip netns exec rt-router nft add table ip packettrail_nat
sudo ip netns exec rt-router nft 'add chain ip packettrail_nat postrouting { type nat hook postrouting priority srcnat; policy accept; }'
sudo ip netns exec rt-router nft add rule ip packettrail_nat postrouting \
  ip saddr 10.50.1.10 ip daddr 10.50.2.10 oifname "rr1" masquerade
```

Captured on destination `rt-b/rb0`:

```text
IP 10.50.2.1 > 10.50.2.10: ICMP echo request, id 4587, seq 1
IP 10.50.2.1 > 10.50.2.10: ICMP echo request, id 4587, seq 2
IP 10.50.2.1 > 10.50.2.10: ICMP echo request, id 4587, seq 3
```

Captured 3 packets; NAT-active ping succeeded **3/3**. Removed the NAT table, checked that the ruleset was empty, and confirmed normal connectivity with **3/3** ping.

## Packet interpretation

- **Before NAT:** `10.50.1.10 -> 10.50.2.10`
- **After SNAT/MASQUERADE:** `10.50.2.1 -> 10.50.2.10`
- Translation occurs on the router; the client still owns `10.50.1.10`. Connection tracking enables inverse NAT of reply traffic.
- `tcpdump` on the destination proves the rewritten *outgoing* source. A successful ping while NAT is active additionally confirms round-trip operation.

See [troubleshooting.md](troubleshooting.md) for symptoms, diagnosis, fixes and verification.

## Cloud & DevOps connections

NAT and firewall policies are foundational to Docker outbound traffic, Linux host firewalls, Kubernetes networking/CNI troubleshooting and cloud egress designs. AWS NAT Gateway is a managed product, not the same implementation as nftables masquerading.

## Next study tasks

Capture both router sides with tcpdump, compare `snat` and `masquerade` when an interface address changes, then practice DNS and conntrack inspection in a disposable namespace topology.
