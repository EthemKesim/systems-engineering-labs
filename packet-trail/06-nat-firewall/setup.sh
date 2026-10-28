#!/usr/bin/env bash
set -euo pipefail
if (( EUID != 0 )); then echo 'Run: sudo bash setup.sh' >&2; exit 1; fi
for command in ip ping sysctl; do command -v "$command" >/dev/null || { echo "Missing command: $command" >&2; exit 1; }; done
for ns in rt-a rt-router rt-b; do
  if ip netns list | awk '{print $1}' | grep -Fxq "$ns"; then echo "Namespace $ns already exists; refusing to change it." >&2; exit 1; fi
done
for iface in ra0 rr0 rb0 rr1; do
  if ip link show "$iface" >/dev/null 2>&1; then echo "Interface $iface already exists; refusing to change it." >&2; exit 1; fi
done
# If setup fails after creating the first namespace, remove only what this invocation created.
created=0
rollback() {
  if (( created == 1 )); then
    echo 'Setup failed; cleaning up newly created lab namespaces.' >&2
    for ns in rt-a rt-router rt-b; do ip netns del "$ns" 2>/dev/null || true; done
    ip link del ra0 2>/dev/null || true
    ip link del rb0 2>/dev/null || true
  fi
}
trap rollback ERR
created=1
ip netns add rt-a
ip netns add rt-router
ip netns add rt-b
ip link add ra0 type veth peer name rr0
ip link add rb0 type veth peer name rr1
ip link set ra0 netns rt-a
ip link set rr0 netns rt-router
ip link set rb0 netns rt-b
ip link set rr1 netns rt-router
ip -n rt-a addr add 10.50.1.10/24 dev ra0
ip -n rt-router addr add 10.50.1.1/24 dev rr0
ip -n rt-router addr add 10.50.2.1/24 dev rr1
ip -n rt-b addr add 10.50.2.10/24 dev rb0
for ns in rt-a rt-router rt-b; do ip -n "$ns" link set lo up; done
ip -n rt-a link set ra0 up
ip -n rt-router link set rr0 up
ip -n rt-router link set rr1 up
ip -n rt-b link set rb0 up
ip -n rt-a route add default via 10.50.1.1
ip -n rt-b route add default via 10.50.2.1
ip netns exec rt-router sysctl -w net.ipv4.ip_forward=1
ip netns exec rt-a ping -c 2 -W 1 10.50.2.10
ip netns exec rt-b ping -c 2 -W 1 10.50.1.10
created=0
trap - ERR
echo 'PacketTrail Lab 06 topology ready.'
