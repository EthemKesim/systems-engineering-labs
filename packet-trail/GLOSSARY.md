# PacketTrail — Networking & Linux Glossary

A practical reference for Linux networking, Cloud Engineering, DevOps, and Kubernetes. Concepts are organized by their relationship to one another, and examples are drawn from the PacketTrail labs.

> **Learning method:** Know what a term means, which layer it belongs to, how to inspect it, and what typically fails. Do not memorize commands without understanding the evidence they provide.

## 1. Linux & Operating System Fundamentals

| Term | Meaning | How we use or inspect it |
|---|---|---|
| **Kernel** | The core of the operating system that manages processes, memory, devices, and networking. | Linux networking features such as veth, bridges, and namespaces are implemented by the kernel. |
| **Process** | A running instance of a program. | `ps`, `pgrep`, `top`; `curl` and `apache2` run as processes. |
| **PID / PPID** | Process identifier / parent process identifier. | `ps -o pid,ppid,cmd -p <PID>` |
| **Daemon** | A long-running background service process. | Apache, Docker, and Gunicorn may run as services. |
| **systemd / Unit** | Linux service manager / a managed unit such as a service. | `systemctl status apache2` |
| **Journal / Log** | Diagnostic events recorded by processes or system services. | `journalctl -u apache2 -n 30 --no-pager` |
| **UID / GID** | Numeric user ID / group ID used in access control. | `id`, `stat` |
| **File permissions** | Read (`r`), write (`w`), and execute (`x`) permissions for owner, group, and others. Directory `x` allows traversal. | `ls -l`, `chmod 600`, `chmod 640` |
| **sudo / Root** | Mechanism to execute authorized commands with another identity / the privileged superuser. | `sudo whoami`, `sudo -u labuser whoami` |
| **Least privilege** | Give users and processes only the permissions they require. | Restrict configuration files and dedicated service accounts. |
| **sysctl** | Interface for reading and changing kernel parameters. | `sysctl net.ipv4.ip_forward` |

## 2. Networking Foundations — From Link to Application

| Term | Meaning | PacketTrail example or command |
|---|---|---|
| **Network interface (NIC)** | An endpoint that sends and receives network traffic; it may be physical or virtual. | `ip -br addr` shows `enp0s1`, `lo`, and virtual interfaces. |
| **Loopback** | Local interface used for communication within the same network namespace. | `127.0.0.1`; `ip link set lo up` |
| **MAC address** | Link-layer identifier used to deliver Ethernet frames on a local network. | `ip link show`, `ip neigh` |
| **Ethernet frame** | Layer 2 unit carrying payload data, with source and destination MAC addresses. | Forwarded by `br-lab`. |
| **IP address** | Layer 3 address assigned to a network interface. | `10.10.10.11/24`, `192.168.64.3/24` |
| **IPv4 / IPv6** | Two versions of the Internet Protocol with different address formats. | `10.50.1.10` / `fe80::...` |
| **CIDR prefix** | Prefix length defining which address bits identify the network. | `/24` is equivalent to IPv4 mask `255.255.255.0`. |
| **Subnet** | IP network range defined by a prefix. | `10.50.1.0/24` and `10.50.2.0/24` are different subnets. |
| **Gateway / Next hop** | Router address to which traffic is sent on the way to a destination. | `default via 10.50.1.1` |
| **Routing table** | Rules used to choose where IP packets should be sent. | `ip route`, `ip route get 1.1.1.1` |
| **Default route** | Fallback route when no more-specific destination route matches. | `ip route add default via 10.50.1.1` |
| **IP forwarding** | Allowing a system to forward incoming IP packets toward other networks. | `sysctl net.ipv4.ip_forward`; Lab 05 routed two subnets. |
| **TTL (Time to Live)** | IPv4 hop limit decreased by routers; prevents indefinite looping. | Ping replies with `ttl=63` in our routed lab. |
| **ARP** | IPv4 Address Resolution Protocol: finds the MAC address for an IPv4 neighbor on the local link. | `ip neigh show` |
| **Neighbor table** | Cache of resolved link-layer neighbors and their states. | `REACHABLE`, `STALE`, `FAILED` shown by `ip neigh`. |
| **ICMP** | Protocol used for control/error reporting and Echo Requests/Replies. | `ping -c 3 <IP>` |
| **Packet loss** | Sent packets that did not result in expected responses during a test. | 100% loss when `veth-br3` was disabled; not always proof of the root cause. |
| **DNS** | Translates hostnames into addresses, among other record lookups. | `getent ahostsv4 example.com`, `resolvectl` |
| **TCP** | Reliable, ordered byte-stream transport protocol using connections. | `ss -tlnp`, `ss -tnp` |
| **UDP** | Datagram transport without TCP's built-in reliable delivery guarantees. | DNS often uses UDP; inspect using `ss -ulnp`. |
| **Port** | Transport-layer number identifying an endpoint for a service or client. | Apache `8080`, Gunicorn `5000`. |
| **Socket** | Operating-system endpoint for network communication. | `ss` displays sockets. |
| **LISTEN** | TCP socket state in which a server waits for inbound connections. | `ss -tlnp` showed Apache on `*:8080`. |
| **ESTABLISHED** | TCP connection state with communication established between endpoints. | `ss -tnp` captured `curl` to `127.0.0.1:8080`. |
| **Ephemeral port** | Temporary client-side source port selected for a connection. | `curl` used local port `51968` in one experiment. |
| **HTTP / HTTPS** | Application-layer web protocol / HTTP carried over TLS for security. | `curl -I http://127.0.0.1:8080` |
| **TLS** | Cryptographic protocol protecting transport of application data, commonly HTTPS. | Inspect with `curl -v https://...` where appropriate. |
| **HTTP status code** | Numeric server response indicating outcome. | `200 OK` from TechNova. |
| **Reverse proxy** | Server that receives client requests and forwards them to backend servers. | Apache `:8080` forwards to Gunicorn `127.0.0.1:5000`. |

## 3. Linux Virtual Networking & Containers

| Term | Meaning | PacketTrail example or command |
|---|---|---|
| **Network namespace (netns)** | Isolated network stack, including interfaces, IP addresses, routes, and socket port space. | `ip netns add ns-a`; `ip netns exec ns-a ...` |
| **veth pair** | Two connected virtual Ethernet interfaces; frames from one end arrive at the other. | `veth-a` ↔ `veth-b` in Lab 03. |
| **Linux bridge** | Software Layer 2 switch joining several Ethernet interfaces. | `br-lab` in Lab 04. |
| **Bridge port / master** | Interface attached to a bridge / the bridge controlling its Layer 2 forwarding. | `ip link set veth-br2 master br-lab` |
| **nomaster** | Removes a network interface from its bridge or other master device. | `ip link set veth-br2 nomaster`; broke ns1→ns2 connectivity. |
| **FDB (Forwarding Database)** | Mapping of MAC addresses to bridge ports, learned from Ethernet frames. | `bridge fdb show br br-lab` |
| **Layer 2 vs Layer 3** | Layer 2 forwards frames using MAC addresses; Layer 3 routes packets using IP addresses. | Bridge in Lab 04 vs router in Lab 05. |
| **Docker bridge network** | Docker's software-network arrangement that commonly uses Linux bridges and veth devices. | Host interface `docker0` and Docker-created bridges. |
| **Container network interface (CNI)** | Container Network Interface specifications and plugins commonly used to set up Pod/container networking. | Useful later in Kubernetes networking labs. |
| **Kubernetes Pod / Service / Ingress** | Pod runs one or more containers; Service exposes a stable logical endpoint; Ingress defines HTTP(S) access rules through a controller. | Concepts to revisit after Linux networking. |

## 4. NAT, Firewalls & Packet Investigation

| Term | Meaning | How to recognize or inspect it |
|---|---|---|
| **NAT (Network Address Translation)** | Rewrites network addresses and potentially ports as traffic passes through a device. | Investigate source/destination addresses before and after routing. |
| **SNAT** | Source NAT changes packet source address (and sometimes port), typically for outgoing traffic. | nftables `postrouting` NAT chain. |
| **DNAT** | Destination NAT changes packet destination address (and sometimes port), often for forwarding to an internal service. | nftables `prerouting` NAT chain. |
| **MASQUERADE** | Dynamic form of source NAT that uses the outgoing interface's address. | nftables `masquerade`; common in container networking. |
| **Firewall** | System that permits, rejects, or drops network traffic according to rules. | `nft list ruleset` |
| **nftables / nft** | Linux packet-filtering and NAT framework / its command-line interface. | `nft list ruleset`; use isolated lab tables. |
| **Table / Chain / Rule** | nftables organization: tables contain chains; chains contain ordered rules. | `table inet ...`, `chain forward`, match-and-verdict rule. |
| **Hook** | Specific stage of packet processing where a base chain runs. | `input`, `forward`, `output`, `prerouting`, `postrouting` |
| **accept / drop / reject** | Permit a packet / silently discard / actively report rejection when supported. | Firewall diagnosis differs based on verdict. |
| **Stateful firewall / conntrack** | Tracks flows so rules can treat established or related packets differently. | `ct state established,related` in nftables rules. |
| **tcpdump** | Packet capture and inspection tool; reveals traffic reaching an interface. | `tcpdump -ni <interface> icmp` |
| **Baseline** | Known-good measurements gathered before changing a system. | 3/3 ping before firewall modifications. |
| **Failure injection** | Intentionally introducing a controlled fault to test understanding and recovery. | Disable a bridge port or forwarding only in a lab. |
| **Root cause** | The actual underlying reason a symptom occurs, supported by evidence. | Apache listened on port `8080`, not port `80`. |
| **Verification** | Repeating tests after a fix to confirm behavior is restored. | Repeat the same `ping` or `curl` used to detect failure. |

## 5. PacketTrail Incidents — Symptom, Diagnosis, Fix

| Lab | Symptom | Diagnostic evidence | Recovery |
|---|---|---|---|
| Lab 02 | HTTP request to port 80 failed | `ss -tlnp`, Apache `Listen 8080` | Request `http://127.0.0.1:8080` |
| Lab 03 | `Network is unreachable` | `ip -br link` showed a down veth; route missing | Bring interface up |
| Lab 03 | Wrong subnet | `ip route` had no path to `10.200.2.0/24` | Restore IP to `10.200.1.2/24` |
| Lab 04 | 100% ping loss to ns3 | `bridge link`: `veth-br3` disabled; `ip neigh`: `FAILED` | `ip link set veth-br3 up` |
| Lab 04 | ns2 unreachable while interface UP | `bridge link` showed missing bridge membership | Reattach `veth-br2` to `br-lab` |
| Lab 04 | `Network is unreachable` after IP change | Different subnets and no route | Restore ns3's original subnet |
| Lab 05 | 100% loss across subnets | Router `ip_forward=0`, routes remained present | Set router's `ip_forward=1` |
| Lab 05 | `Network is unreachable` | Client default route missing | Restore default route via `10.50.1.1` |

## 6. Troubleshooting Routine

1. **Define the symptom:** Which source, destination, protocol, and port failed?
2. **Check local state:** `ip -br addr`, `ip -br link`, `ss -tlnp`.
3. **Check Layer 2:** `ip neigh`, `bridge link`, `bridge fdb` when applicable.
4. **Check Layer 3:** `ip route`, `ip route get`, forwarding setting.
5. **Check filtering/NAT:** `nft list ruleset`, counters, and `tcpdump` captures.
6. **Apply the smallest safe fix.**
7. **Verify:** Repeat the original failing test; document before/after evidence.

## 7. Related Cloud & DevOps Terms to Learn Next

- **VPC / Subnet / Route Table / Internet Gateway / NAT Gateway (AWS):** Cloud virtual networking constructs; compare their purpose with Linux routing and NAT, without assuming identical implementations.
- **Security Group / Network ACL (AWS):** Cloud network filtering controls with distinct statefulness and rule semantics.
- **Load Balancer / Health Check:** Traffic distribution and application availability checks.
- **Observability:** Logs, metrics, traces, and network evidence used to understand system behavior.
- **SLO / SLI / Error Budget:** Reliability measurement and objectives in SRE.
- **Infrastructure as Code (IaC):** Reproducible infrastructure definitions (e.g., Terraform).
- **GitOps:** Declarative desired-state deployment workflow, often used for Kubernetes.
- **Network Policy:** Kubernetes rules governing allowed Pod network traffic when enforced by the network plugin.

---

**Update rule:** After each PacketTrail lab, add only terms used or meaningfully introduced, with a short definition, a command or concrete example, and a link to the relevant lab or incident.

## Lab 06 Addendum — NAT, Packet Filtering & Repeatability

| Term | Definition | PacketTrail evidence / command |
|---|---|---|
| **Source NAT (SNAT)** | Translation of a packet's source IP, often during postrouting. | `snat to 10.50.2.1`; rt-b saw 10.50.2.1 instead of 10.50.1.10. |
| **Destination NAT (DNAT)** | Translation of a packet's destination address, usually before routing. | Relevant to port forwarding; not yet tested in this lab. |
| **MASQUERADE** | Dynamic form of SNAT that uses an appropriate outgoing interface address. | `oifname "rr1" masquerade`; three translated ICMP requests captured. |
| **Netfilter** | Linux kernel framework for packet processing, filtering, NAT and conntrack integration. | nftables hooks and chains in rt-router. |
| **nftables** | Linux firewall/NAT rule framework managed by `nft`. | `nft list ruleset`, `nft add rule`, `nft delete table`. |
| **Table** | Container for nftables chains within a protocol family. | `inet packettrail`, `ip packettrail_nat`. |
| **Chain** | Ordered set of packet processing rules, optionally attached to a hook. | `forward`, `postrouting`. |
| **Hook** | Kernel packet-processing stage where a base chain executes. | `hook forward`, `hook postrouting`. |
| **FORWARD** | Path for packets being routed through, rather than addressed to, the current namespace. | `rt-a -> rt-b` ICMP filtered by router. |
| **POSTROUTING** | Hook after a routing decision, before a packet leaves. | Source translation in `postrouting`. |
| **PREROUTING** | Hook before the routing decision on incoming traffic. | Often used for DNAT; not tested yet. |
| **Drop rule** | Discards matching packets without sending them forward. | `counter drop`; 3 packets / 252 bytes. |
| **Rule counter** | Packet and byte totals for traffic matching a rule. | `nft list table inet packettrail`. |
| **Connection tracking (conntrack)** | Tracks flow state and NAT mappings so replies can be translated consistently. | Explains return traffic in the SNAT/MASQUERADE experiments. |
| **Packet capture** | Observation of network packets on an interface. | `tcpdump -ni rb0 -c 3 'icmp...'`. |
| **Baseline** | Known-good behavior recorded before changing the system. | Initial 3/3 pings before firewall testing. |
| **Failure injection** | Controlled introduction of a fault to study behavior and recovery. | Targeted ICMP `drop` rule. |
| **Recovery verification** | Re-running the original failing test after a fix. | Ping succeeded 3/3 after rule removal. |
| **Repeatable automation** | Scripted, consistent reconstruction of a working environment. | `sudo bash setup.sh` recreated the three namespaces. |
| **Idempotence** | Repeating an operation produces the same intended end state without unintended additional changes. | Current script refuses to overwrite an existing topology; it is deliberately not fully idempotent. |
