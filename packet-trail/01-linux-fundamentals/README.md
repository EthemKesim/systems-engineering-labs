# Lab 01 — Linux Process Management & Troubleshooting

## Overview

This lab focuses on understanding Linux process management, system resource monitoring, service management, and basic troubleshooting.

The goal is to develop practical Linux administration skills through hands-on experiments, observation, and repeated troubleshooting exercises.

## Lab Environment

| Component | Configuration |
|---|---|
| Operating System | Ubuntu 26.04 LTS |
| Architecture | ARM64 |
| Virtualization | UTM / QEMU |
| Kernel | Linux 7.0.0-29-generic |
| Hostname | lab-ubuntu |
| User | ethem |

## Learning Objectives

- Understand Linux processes and parent-child relationships.
- Identify processes using PID and PPID.
- Start, monitor, and terminate background processes.
- Understand process signals, including SIGTERM.
- Monitor CPU, memory, swap, and system load.
- Inspect systemd services.
- Investigate service logs using journalctl.
- Develop a systematic troubleshooting approach.

---

## Experiment 1 — Process Management

**Objective:** Create a background process, identify its PID, inspect its parent process, and terminate it safely.

### Commands

```bash
sleep 300 &
jobs -l
pgrep -a sleep

echo $$
ps -o pid,ppid,user,stat,cmd -p $$

ps -p 4720 -o pid,ppid,stat,cmd
kill 4720
jobs -l
```

### Observations

- Started `sleep 300` as a background process.
- The background process received PID `4720`.
- The Bash shell had PID `4143`, with parent PID `4092`.
- Used `ps` to inspect process information.
- Sent SIGTERM to the background process using `kill`.
- Verified that the process terminated successfully.

### Key Concepts

| Term | Explanation |
|---|---|
| PID | Unique identifier of a running process |
| PPID | Identifier of the parent process |
| Background Job | A process started without blocking the shell |
| SIGTERM | Signal requesting graceful process termination |
| Bash | Command interpreter used to interact with Linux |

**Learning outcome:** Understood how Linux processes are created, identified, monitored, and terminated.

---

## Experiment 2 — System Resource Monitoring

**Objective:** Inspect system resource utilization and understand basic performance indicators.

### Commands

```bash
top
free -h
uptime
```

### Recorded Results

| Metric | Observed Value |
|---|---|
| Total Memory | 3.3 GiB |
| Used Memory | 2.4 GiB |
| Available Memory | 956 MiB |
| Swap Usage | 94 MiB |
| System Uptime | Approximately 16 minutes |
| Load Average (1 minute) | 0.10 |

These values represent a single observation and may change between executions.

### Findings

- `top` displayed active processes and their CPU and memory consumption.
- `free -h` showed memory availability and swap usage.
- `uptime` displayed system uptime and load averages.
- The system had a low load average during the recorded measurement.
- Available memory was more informative than free memory alone.

**Learning outcome:** Practiced checking Linux resource utilization before investigating potential performance issues.

---

## Experiment 3 — Linux Service Management

**Objective:** Inspect running services and understand how systemd manages background services.

### Commands

```bash
systemctl status docker --no-pager
systemctl status containerd --no-pager
systemctl status apache2 --no-pager
```

### Observations

| Service | Status | Purpose |
|---|---|---|
| Docker | Active (running) | Container management |
| containerd | Active (running) | Container runtime |
| Apache | Active (running) | HTTP web server |

All three services were running during the experiment.

No service was stopped, restarted, or reconfigured.

### Key Concepts

- **systemd:** Linux system and service manager.
- **Daemon:** A program that provides services in the background.
- **Service Unit:** A configuration unit used by systemd to manage a service.
- **Active (running):** Indicates that a service is currently running.

**Learning outcome:** Learned how to inspect service status without modifying running workloads.

---

## Experiment 4 — Log Investigation

**Objective:** Inspect Docker service logs and identify possible operational warnings.

### Command

```bash
sudo journalctl -u docker -n 20 --no-pager
```

### Observations

The Docker startup logs contained warnings involving:

- Container mount state detection.
- Missing container sandbox identifiers.
- Network rule cleanup.

Despite these messages, Docker successfully completed initialization and remained active.

The Apache service also reported a warning related to its `ServerName` configuration.

### Troubleshooting Analysis

A warning message does not necessarily mean a service has failed.

Before applying changes, an engineer should:

1. Check whether the service is running.
2. Identify the warning or error message.
3. Determine whether the issue affects functionality.
4. Collect additional evidence when necessary.
5. Apply changes only after identifying a probable root cause.
6. Verify the result.

No configuration changes were made during this experiment.

**Learning outcome:** Practiced distinguishing informational messages, warnings, and actual service failures.

---

## Practical Connections to Cloud & DevOps

| Linux Concept | Real-World Application |
|---|---|
| PID / PPID | Investigating application processes |
| Signals | Graceful shutdown of applications and containers |
| CPU / Memory | Monitoring cloud server performance |
| systemd | Managing services on Linux servers |
| journalctl | Diagnosing failed or unstable services |
| Process Troubleshooting | Investigating Docker and Kubernetes workloads |

These concepts will be revisited during future Docker, Kubernetes, and cloud infrastructure labs.

---

## Lessons Learned

This lab demonstrated that understanding Linux systems requires more than memorizing commands.

The most important takeaways were:

- Every running program is associated with a process.
- Parent-child relationships help explain how processes are started.
- Resource utilization should be investigated using multiple metrics.
- systemd provides tools for inspecting and managing services.
- Logs provide evidence for diagnosing operational problems.
- A service can remain healthy even when its logs contain warnings.
- Troubleshooting should focus on evidence and root-cause analysis before making changes.

## Next Steps

- Linux filesystem navigation and directory structure.
- File ownership and permissions.
- Users, groups, and sudo.
- Controlled permission-denied troubleshooting.
- Repeating process management exercises without step-by-step instructions.

## Status

**Completed:** Initial process management, resource monitoring, service inspection, and log investigation experiments.

**Planned:** Independent repetition and additional troubleshooting challenges.
