# Intentional Divergences From Upstream

This document tracks deliberate differences so future sync work can separate intentional choices from accidental drift.

## Scope Rule

- Prefer upstream architecture and tooling conventions.
- Keep personal application stacks and personal workstation configuration out of this repository unless required by architecture contracts.

## Intentional Divergences

## 1. Personal Application Modules Are Not Imported

Examples:
- Personal desktop/app module sets under modules/home and modules/hosts from upstream.

Reason:
- These are user-specific preferences rather than shared architecture.

## 2. Secrets Portability Behavior Is Preserved

Examples:
- Dynamic NIX_SECRETS_DIR export in shellHook.
- Host-level sops fallback from shared.yaml to host file for password secrets.

Reason:
- Improves portability and migration safety across environments.

## 3. Package Exposure Path Remains pkgs/common

Reason:
- Existing repository structure and usage expectations are preserved while architecture converges.

## 4. Current Host Inventory Remains Lean

Examples:
- Active host inventory is minimal compared with upstream.

Reason:
- Repository purpose is architecture/tooling parity without importing upstream personal deployment breadth.

## 5. Existing Tests and Script Workflow Are Preserved

Examples:
- Bats-based checks and script-driven rebuild/bootstrap workflow.

Reason:
- Local reliability and operational familiarity.

## Validation Policy

When updating from upstream:
- Treat this file as allowlist documentation.
- Any newly discovered difference not listed here should be treated as potential drift until reviewed.
