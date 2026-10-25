# Lab 02 — TCP/IP & Linux Networking Fundamentals

## Overview

This lab explores Linux network interfaces, IP addressing, routing, DNS resolution, TCP sockets, and HTTP connectivity.

The objective is to understand how applications communicate across networks and practice troubleshooting using real evidence.

## Environment

- OS: Ubuntu 26.04 LTS (ARM64)
- Virtualization: UTM / QEMU
- Hostname: `lab-ubuntu`

## 1. Network Interfaces

### Commands

```bash
ip -br addr
ip link show
```

**Command explanations:**

- `ip`: Linux utility for inspecting and configuring networking.
- `-br`: Displays a brief output.
- `addr`: Shows IP addresses assigned to interfaces.
- `link show`: Displays interface status and link-layer information.

### Observations

| Interface | IPv4 Address | State |
|---|---|---|
| lo | 127.0.0.1/8 | UNKNOWN (loopback operational) |
| enp0s1 | 192.168.64.3/24 | UP |
| docker0 | 172.17.0.1/16 | DOWN |
| Docker bridge 1 | 172.18.0.1/16 | DOWN |
| Docker bridge 2 | 172.19.0.1/16 | DOWN |

The Ubuntu VM uses `enp0s1` as its primary network interface.

## 2. Routing

### Command

```bash
ip route get 1.1.1.1
```

**Explanation:** Shows the route Linux would select for the specified destination.

### Result

- Destination: 1.1.1.1
- Gateway: 192.168.64.1
- Interface: enp0s1
- Source IP: 192.168.64.3

This demonstrates how Linux chooses the network path for outgoing traffic.

## 3. Network Connectivity

### Command

```bash
ping -c 4 1.1.1.1
```

**Explanation:**

- `ping`: Sends ICMP Echo Requests.
- `-c 4`: Sends four requests.

### Result

- 4 packets transmitted
- 4 packets received
- 0% packet loss
- Average round-trip time: approximately 13.6 ms

The target was reachable through ICMP during the test.

## 4. DNS Resolution

### Command

```bash
getent ahostsv4 example.com
```

**Explanation:** Resolves a hostname using the system's configured name service mechanisms.

### Result

`example.com` successfully resolved to IPv4 addresses.

DNS resolution was operational during the test.

## 5. TCP Listening Ports

### Command

```bash
sudo ss -tlnp
```

**Options:**

- `-t`: TCP sockets
- `-l`: Listening sockets
- `-n`: Numeric addresses and ports
- `-p`: Process information

### Observations

- Apache listened on port 8080.
- Gunicorn listened on 127.0.0.1:5000.
- SSH was listening on port 22.

## 6. HTTP Connectivity

### Commands

```bash
curl -I --max-time 5 http://127.0.0.1
curl -I --max-time 5 http://127.0.0.1:8080
curl -v --max-time 5 http://127.0.0.1:8080/
curl -I --max-time 5 http://127.0.0.1:5000
```

**Explanation:**

- `curl`: Makes HTTP requests.
- `-I`: Requests HTTP headers.
- `-v`: Displays verbose connection details.
- `--max-time 5`: Limits the request duration to five seconds.

### Results

- Port 80: Connection refused.
- Port 8080: HTTP 200 OK.
- Port 5000: HTTP 200 OK.
- The response from port 8080 contained the TechNova Application HTML.

## 7. TCP Connection States

### Commands

```bash
curl --limit-rate 1k --max-time 15 \
  http://127.0.0.1:8080/ -o /dev/null &

ss -tnp
wait
```

### Observations

A TCP connection was observed in the `ESTABLISHED` state.

- Client: `127.0.0.1:51968`
- Server: `127.0.0.1:8080`
- Client process: `curl`

The client used a temporary source port to communicate with the server.

## Key Concepts

| Concept | Meaning |
|---|---|
| IP Address | Identifies a network interface at the IP layer |
| Subnet | Defines a network address range |
| Gateway | Router used to reach another network |
| Routing | Determines where outgoing packets are sent |
| DNS | Resolves names to network addresses |
| TCP | Provides reliable, ordered byte-stream communication |
| Port | Identifies a transport-layer endpoint |
| Socket | Operating system endpoint for network communication |
| LISTEN | Waiting for incoming TCP connections |
| ESTABLISHED | Active TCP connection |

## Cloud & DevOps Relevance

These concepts are directly applicable to:

- AWS VPC routing and connectivity
- Docker bridge networking
- Kubernetes Services and Ingress
- Application Load Balancers
- Linux server troubleshooting
- DNS and HTTP connectivity investigation

## Lessons Learned

A running application service does not necessarily listen on the expected port.

Troubleshooting should distinguish service status, listening sockets, network routing, DNS resolution, and HTTP responses.

Using `ss`, `curl`, `ip`, and system logs together provides stronger evidence than relying on a single command.

## Next Steps

- Complete and document the Apache/Gunicorn proxy investigation.
- Practice additional TCP troubleshooting scenarios.
- Build isolated networks with Linux network namespaces and veth pairs.
