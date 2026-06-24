<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
<!-- TOPOLOGY.md — Project architecture map and completion dashboard -->
<!-- Last updated: 2026-02-19 -->

# flatracoon — Project Topology

## System Architecture

```
                        ┌─────────────────────────────────────────┐
                        │              APPLICATIONS               │
                        │        (Userspace, Services)            │
                        └───────────────────┬─────────────────────┘
                                            │ System Calls / IPC
                                            ▼
                        ┌─────────────────────────────────────────┐
                        │           OS CORE & NETSTACK            │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ OS Kernel │  │  Networking       │  │
                        │  │ (Core)    │  │  Stack            │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │           INTERFACE LAYER               │
                        │  ┌───────────┐  ┌───────────────────┐  │
                        │  │ Idris2 ABI│  │     Zig FFI       │  │
                        │  │ (Proofs)  │  │ (Memory Safety)   │  │
                        │  └─────┬─────┘  └────────┬──────────┘  │
                        └────────│─────────────────│──────────────┘
                                 │                 │
                                 ▼                 ▼
                        ┌─────────────────────────────────────────┐
                        │             HARDWARE / HAL              │
                        │      (Bare metal, VirtIO, Drivers)      │
                        └─────────────────────────────────────────┘

                        ┌─────────────────────────────────────────┐
                        │          REPO INFRASTRUCTURE            │
                        │  Justfile / Mustfile  .machine_readable/│
                        │  ABI-FFI Standards    Git Submodules    │
                        └─────────────────────────────────────────┘
```

## Completion Dashboard

```
COMPONENT                          STATUS              NOTES
─────────────────────────────────  ──────────────────  ─────────────────────────────────
OS CORE (os/)
  Kernel Implementation             ████░░░░░░  40%    Initial scheduler active
  Idris2 ABI (Proofs)               ██████████ 100%    Type-level layout verified
  Zig FFI Bridge                    ████████░░  80%    Memory safe HAL refining

NETSTACK (netstack/)
  Packet Processing                 ██████░░░░  60%    IPv6-native parsing active
  Socket Layer                      ████░░░░░░  40%    TCP/UDP stubs verified
  Hardware Drivers                  ██░░░░░░░░  20%    VirtIO-net prototyping

REPO INFRASTRUCTURE
  Justfile Automation               ██████████ 100%    Standard build tasks
  .machine_readable/                ██████████ 100%    STATE.a2ml tracking
  Submodule Management              ██████████ 100%    Component isolation stable

─────────────────────────────────────────────────────────────────────────────
OVERALL:                            █████░░░░░  ~50%   Infrastructure stable, OS maturing
```

## Key Dependencies

```
Idris2 ABI ──────► Zig FFI Bridge ──────► OS Kernel ──────► HAL/Hardware
     │                 │                    │                 │
     ▼                 ▼                    ▼                 ▼
Generated Header ──► Netstack ───────────► Sockets ───────► Applications
```

## Update Protocol

This file is maintained by both humans and AI agents. When updating:

1. **After completing a component**: Change its bar and percentage
2. **After adding a component**: Add a new row in the appropriate section
3. **After architectural changes**: Update the ASCII diagram
4. **Date**: Update the `Last updated` comment at the top of this file

Progress bars use: `█` (filled) and `░` (empty), 10 characters wide.
Percentages: 0%, 10%, 20%, ... 100% (in 10% increments).
