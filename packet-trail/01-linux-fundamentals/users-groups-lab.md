# Lab 01 — Linux Users, Groups & sudo

## Objective

Understand Linux user identities, group membership, file ownership, privilege escalation, and access control through practical experiments.

## Environment

- Ubuntu 26.04 LTS (ARM64)
- UTM / QEMU
- Hostname: `lab-ubuntu`
- Primary user: `ethem`

## Experiment 1 — User and Group Inspection

Commands:

```bash
whoami
id
groups
getent passwd ethem
getent group sudo
```

### Observations

- The primary user was `ethem` with UID `1000`.
- The account belonged to several supplementary groups, including `sudo`.
- User and group information was retrieved using `getent`.

## Experiment 2 — Creating a Test User

Commands:

```bash
sudo useradd -m -s /bin/bash labuser
sudo groupadd labteam
sudo usermod -aG labteam labuser

id labuser
getent group labteam
ls -ld /home/labuser
```

### Results

- Created user `labuser` (UID `1006`).
- Created group `labteam` (GID `1011`).
- Added `labuser` to `labteam`.
- Verified the user's home directory and group membership.

## Experiment 3 — Private File Access

Created a private configuration file using:

```bash
mkdir -p ~/linux-users-lab
echo "Private configuration" > ~/linux-users-lab/secret.conf

chmod 700 ~/linux-users-lab
chmod 600 ~/linux-users-lab/secret.conf

sudo -u labuser cat /home/ethem/linux-users-lab/secret.conf
```

Result: `Permission denied`.

The test user could not read the file because the required directory traversal and file access permissions were not available.

## Experiment 4 — Group-Based Access

Created a shared directory under `/tmp` with:

- Directory owner: `ethem`
- Directory group: `labteam`
- Directory permissions: `750`
- File owner: `ethem`
- File group: `labteam`
- File permissions: `640`

Verified that `labuser` could read `team.txt` and received:

```text
Shared team document
```

## Challenge — Permission Failure and Recovery

Changed the file permissions from `640` to `600`.

```bash
chmod 600 /tmp/packettrail-group-lab/team.txt
sudo -u labuser cat /tmp/packettrail-group-lab/team.txt
```

Result: `Permission denied`.

Restored group read access:

```bash
chmod 640 /tmp/packettrail-group-lab/team.txt
sudo -u labuser cat /tmp/packettrail-group-lab/team.txt
```

Result: `Shared team document`.

This demonstrated that group membership alone does not grant access; the file and directory permissions must also allow it.

## Experiment 5 — sudo and Execution Identity

Commands:

```bash
whoami
sudo whoami
sudo -u labuser whoami
```

Results:

```text
ethem
root
labuser
```

## Key Concepts

- UID and GID
- Users and supplementary groups
- File ownership
- Permission bits: read, write, execute
- Directory traversal permissions
- sudo and privilege escalation
- Least privilege
- Access-denied troubleshooting

## Cloud & DevOps Relevance

These concepts are useful for Linux server administration, application service accounts, Docker file ownership, Kubernetes security contexts, and secure infrastructure operations.

## Lessons Learned

Access to a file depends on the effective user identity, group membership, and applicable filesystem permissions.

A troubleshooting workflow should identify which permission boundary is preventing access before modifying it.

## Status

Completed: User and group administration, private file access, group-based sharing, sudo identity checks, and controlled permission failure/recovery.

Next: Mixed Linux fundamentals review and TCP/IP networking.
