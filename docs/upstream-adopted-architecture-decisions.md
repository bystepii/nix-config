# Upstream Adopted Architecture Decisions

This document records architecture/tooling conventions adopted from upstream and adapted for this repository.

## 2026-03-17

## 1. Flake Composition Uses flake-parts

Decision:
- Switched flake output composition to flake-parts mkFlake with perSystem.

Adopted from:
- Upstream composition pattern in flake.nix.

Adaptation in this repo:
- Kept existing host builder logic and host inventory.
- Kept current package path layout under pkgs/common.
- Kept current release branch pins.

Rationale:
- Improves architectural parity and lowers drift in future upstream syncs.

## 2. Special Args Contract Includes namespace and secrets

Decision:
- Added namespace and secrets to specialArgs for host and minimal host builders.

Adopted from:
- Upstream specialArgs conventions.

Adaptation in this repo:
- namespace is set to stepii.
- secrets alias maps to inputs.nix-secrets.

Rationale:
- Aligns module composition semantics and simplifies future portability of upstream-style modules.

## 3. Shared Module Ownership for Nix Policy

Decision:
- Moved common nix settings into modules/common/nix.nix.

Adopted from:
- Upstream shared common module design.

Adaptation in this repo:
- Preserved allowUnfree behavior and optional sops token include logic.

Rationale:
- Reduces duplication and keeps policy centralized.

## 4. Core Import Graph Includes Architecture Utilities

Decision:
- Core host graph imports disko and nix-index-database modules.

Adopted from:
- Upstream core host wiring pattern.

Adaptation in this repo:
- Kept current host module set and did not import personal app layers.

Rationale:
- Improves baseline tooling parity without importing personal runtime choices.

## 5. Overlay and Checks Composition Patterns Converged

Decision:
- Overlay composition uses named overlay set merged into default.
- Checks reuse introdus hook abstraction with local overrides.

Adopted from:
- Upstream overlay and checks composition style.

Adaptation in this repo:
- Kept local bats-test and existing policy hooks.

Rationale:
- Better maintainability and less hook duplication.

## 6. Minimal Host Generation is Path-Driven

Decision:
- Replaced hardcoded minimal installer map with per-host file discovery.

Adopted from:
- Upstream path-driven minimal host generation approach.

Adaptation in this repo:
- Hosts are eligible for minimal generation when required host files exist.
- iso is excluded from minimal variants.

Rationale:
- Removes flake-level host-specific disk data and improves maintainability.
