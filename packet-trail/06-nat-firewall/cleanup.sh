#!/usr/bin/env bash
set -euo pipefail
if (( EUID != 0 )); then echo 'Run: sudo bash cleanup.sh' >&2; exit 1; fi
# Do not delete namespaces with these names unless they match the PacketTrail lab topology.
for ns in rt-a rt-router rt-b; do
  if ! ip netns list | awk '{print $1}' | grep -Fxq "$ns"; then
    echo "Expected namespace $ns missing; no cleanup performed." >&2
    exit 1
  fi
done
for spec in 'rt-a ra0 10.50.1.10/24' 'rt-router rr0 10.50.1.1/24' 'rt-router rr1 10.50.2.1/24' 'rt-b rb0 10.50.2.10/24'; do
  read -r ns iface address <<< "$spec"
  if ! ip -n "$ns" -o -4 addr show dev "$iface" | grep -Fq "$address"; then
    echo "Unexpected topology: $ns/$iface/$address missing. Refusing cleanup." >&2
    exit 1
  fi
done
echo 'Verified Lab 06 topology (rt-a, rt-router, rt-b).'
if [[ "${1:-}" != '--delete' ]]; then
  echo 'Dry run only. To remove these three namespaces, run: sudo bash cleanup.sh --delete'
  exit 0
fi
# Namespace deletion also tears down their veth interfaces. No host networking or Docker resources touched.
for ns in rt-a rt-router rt-b; do ip netns del "$ns"; done
echo 'Lab 06 namespaces removed.'
