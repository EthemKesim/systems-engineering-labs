# Linux Filesystem & Permissions Lab

## Objective

Practice Linux filesystem navigation, file ownership,
permission management, and troubleshooting.

## Environment

- Ubuntu 26.04 LTS ARM64
- UTM / QEMU
- Hostname: lab-ubuntu
- User: ethem

## Experiment 1 — Filesystem Navigation

Commands:

    cd ~
    pwd
    whoami
    ls -lah
    ls /
    ls /etc | head
    ls /var/log | head
    ls /proc | head

Learned the purpose of home directories, system
configuration directories, logs, and process information.

## Experiment 2 — File Operations

Commands:

    mkdir -p ~/linux-permissions-lab
    cd ~/linux-permissions-lab
    touch notes.txt
    echo "PacketTrail Linux Lab" > notes.txt
    cat notes.txt
    ls -l

Successfully created a working directory and text file.

## Experiment 3 — Permissions

Tested:

- chmod 600: owner read/write only
- chmod 644: owner read/write, others read
- chmod 400: owner read only

Verified changes using ls -l.

## Experiment 4 — Permission Denied

Removed write permission from notes.txt using chmod 400.

Attempting to append text produced:

    bash: notes.txt: Permission denied

Restored write permission using chmod 600.

Verified the fix by appending new content.

## Experiment 5 — Ownership

Commands:

    id
    groups
    stat notes.txt

Observed:

- User: ethem
- UID: 1000
- Primary GID: 1000
- File owner: ethem
- File group: ethem

## Challenge — Secure Configuration File

Created app.conf and deliberately removed write permission.

Confirmed the Permission denied error.

Restored write access and verified file contents.

Final intended permissions: 600 (owner read/write only).

## Cloud & DevOps Relevance

These concepts are essential for:

- Linux server administration
- SSH key and configuration security
- Docker volume permissions
- Kubernetes file access
- Troubleshooting application permission failures

## Lessons Learned

File permissions determine who can read, modify,
or execute files.

Troubleshooting requires checking ownership and
permissions before changing configurations.

A permission setting must match the application's
security requirements.

## Next Steps

- Users, groups, and sudo
- Service permissions
- Repeated permission troubleshooting
- Linux networking fundamentals
