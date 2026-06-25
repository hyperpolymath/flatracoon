<!--
SPDX-License-Identifier: CC-BY-SA-4.0
SPDX-FileCopyrightText: 2025-2026 Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->

Consolidated monorepo holding Flatracoon’s operating-system and
networking-stack components, plus the supporting CI / RSR scaffolding.

# Components

- `os/` — operating-system core. The bare-metal / userspace layer of the
  Flatracoon OS proper.

- `netstack/` — independent network stack implementation (sits above or
  alongside `os/`).

Each component is autonomous in its build, but they share licensing, CI,
and the estate-wide governance bundle inherited from
`hyperpolymath/standards`.

# Why a monorepo

This repo was consolidated from previously-separate clones into a single
monorepo to share CI / governance / dependency-version state across the
two components. Each subdirectory still has its own `Justfile` /
`Cargo.toml` / build entry points; the monorepo just collapses the
operational overhead.

# Quickstart

```bash
git clone git@github.com:hyperpolymath/flatracoon.git
cd flatracoon

# OS:
cd os/
just build && just test

# Netstack:
cd ../netstack/
just build && just test
```

# Architecture

See <a href="TOPOLOGY.md" class="md">TOPOLOGY</a> for the visual
architecture map and the component-by-component completion dashboard.

# Status

- **Licence**: MPL-2.0. See [LICENSE](LICENSE); `LICENSES/` carries the
  full REUSE-compliant set.

- **Estate role**: research / experimental — not yet a downstream
  consumer of stable services.

- **Audit findings**: see `docs/tech-debt-2026-05-26.md` if present
  (added by the 2026-05-26 estate tech-debt scan).

# Contributing

See <a href="CONTRIBUTING.md" class="md">CONTRIBUTING</a>. All commits
must be GPG-signed and follow conventional-commit conventions
(estate-wide policy from `hyperpolymath/standards`).

# Companion repositories

- [`hyperpolymath/standards`](https://github.com/hyperpolymath/standards)
  — canonical estate-wide standards.

- [`hyperpolymath/rsr-template-repo`](https://github.com/hyperpolymath/rsr-template-repo)
  — the RSR scaffold this repo follows.
