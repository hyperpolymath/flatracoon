<!--
SPDX-License-Identifier: CC-BY-SA-4.0
Copyright (c) Jonathan D.A. Jewell <j.d.a.jewell@open.ac.uk>
-->
# Changelog

All notable changes to `flatracoon` will be documented in this file.

This file is generated from conventional commits by the
[`changelog-reusable.yml`](https://github.com/hyperpolymath/standards/blob/main/.github/workflows/changelog-reusable.yml)
workflow (`hyperpolymath/standards#206`). Adopt the workflow in this repo's CI to keep this file in sync automatically — see
[`templates/cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml)
for the canonical config.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/);
this project aims to follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- feat(crg): add crg-grade and crg-badge justfile recipes
- feat: add stapeln.toml container definition
- feat: add UX Justfile with doctor, tour, help-me, assail recipes
- feat: deploy UX Manifesto infrastructure
- feat: add CLADE.a2ml — clade taxonomy declaration
- feat: add mirror.yml workflow for GitLab/Bitbucket mirroring
- feat: update netstack STATE.scm with real project status
- feat: initialize all 11 netstack submodules
- feat: add hesiod-dns-map module manifest for orchestrator discovery\n\nEnables ModuleDiscovery to find hesiod-dns-map via *.manifest.ncl scan.\nManifest declares naming layer, health/metrics endpoints, and kubectl\ndeployment mode for the Hesiod DNS service.\n\nCo-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
- feat: consolidate flatracoon-netstack and flatracoon-os into flatracoon monorepo

### Fixed

- fix(ci): pin upload-artifact to valid SHA in hypatia-scan.yml (Refs standards#48) (#11)
- fix(ci): sync hypatia-scan.yml to canonical (kill cd-scanner build drift) (#10)
- fix(ci): build Hypatia escript from repo root (estate dogfood drift)
- fix(ci): adopt canonical hypatia-scan.yml (env.HOME/scanner-layout + Comment-step gate) (#9)
- fix(ci): move secret-scanner Cargo.toml gate from job-level if: to step-level (#8)
- fix(ci): rsr-antipattern.yml duplicate heredoc (#7)
- fix: set correct Groove capability type (was: custom)
- fix(scorecard): enforce granular permissions and add fuzzing placeholder
- fix: global MPL-2.0 → MPL-2.0-or-later replacement
- fix: SPDX headers (AGPL→PMPL), email, author name

### Changed

- refactor: migrate 6SCM → 6A2 (.scm → .a2ml format)

### Documentation

- docs: record tech-debt audit findings (2026-05-26) (#15)
- docs: substantive CRG C annotation (EXPLAINME.adoc)
- docs: Add CRG C test documentation for hesiod-dns-map
- docs: add EXPLAINME.adoc — prove-it file backing README claims
- docs: add 0-AI-MANIFEST.a2ml (RSR compliance)

### CI

- ci(secret-scanner): drop duplicate --fail from trufflehog extra_args (#6)
- ci: fix workflow-linter YAML parse error + self-flag bug
- ci(antipattern): fix top-level dir matching + benchmarks/lsp/bench filename allowlists (#5)
- ci(antipattern): TS check reads .claude/CLAUDE.md exemption table (#4)
- ci(antipattern): broaden TS allowlist (cli/, mod.ts, lsp-server, *vscode*, deno-*) (#3)

## Pre-history

Prior commits to this file's introduction are recorded in git history but not formally classified into Keep-a-Changelog sections. To backfill, run `git cliff -o CHANGELOG.md` locally using the canonical [`cliff.toml`](https://github.com/hyperpolymath/standards/blob/main/templates/cliff.toml) — this is one-shot mechanical work.

---

<!-- This file was seeded by the 2026-05-26 estate tech-debt audit follow-up (Row-2 Phase 3); see [`hyperpolymath/standards/docs/audits/2026-05-26-estate-documentation-debt.md`](https://github.com/hyperpolymath/standards/blob/main/docs/audits/2026-05-26-estate-documentation-debt.md). -->
