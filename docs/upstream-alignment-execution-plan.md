# Upstream Alignment Execution Plan

Goal: align repository architecture and tooling with upstream while preserving intentional custom behavior and excluding personal app stacks.

## Scope Rules

- [x] Prefer upstream conventions for architecture and tooling.
- [x] Preserve intentional custom behavior (scripts/tests/secrets flow portability).
- [x] Do not import personal app stacks unless required by architecture contracts.

## Phase 1 - Baseline and Guardrails

- [x] Record baseline evaluations/build commands for representative hosts.
- [x] Confirm non-goals and invariants in writing (what will not be imported).
- [x] Add a per-phase verification checklist.

## Phase 2 - Flake and Composition Convergence

- [x] Refactor flake composition toward upstream flake-parts structure where applicable.
- [x] Normalize host discovery and minimal host generation flow.
- [x] Align specialArgs contract (inputs/outputs/lib/secrets/namespace).

## Phase 3 - Shared Module Layer Alignment

- [x] Introduce shared Nix policy module pattern from upstream.
- [x] Add monitor schema module from upstream (kept optional unless explicitly enabled).
- [x] Expand host-spec architecture-level options for upstream compatibility.
- [x] Move duplicated host-level Nix policy into shared module ownership.

## Phase 4 - Core Wiring, Overlays, Checks, Shell

- [x] Align core host import graph with upstream architecture-level modules.
- [x] Align overlay composition pattern with upstream merge model.
- [x] Align checks abstraction with upstream while keeping local test coverage.
- [x] Align dev shell conventions while keeping portability improvements.

## Phase 5 - Secrets and SOPS Contract Hardening

- [x] Normalize starter-era fallback comments/logic in host-level sops module.
- [x] Re-verify impermanence + sops key-path invariants.

## Phase 6 - Documentation and Drift Controls

- [x] Add architecture decision notes for adopted upstream patterns.
- [x] Document intentional divergences and rationale.

## Verification Checklist (Run per Phase)

- [x] Evaluate representative host outputs.
- [x] Evaluate minimal host outputs.
- [x] Run flake checks relevant to touched paths.
- [ ] Run test/check scripts relevant to changed modules.
- [ ] Validate secrets/sops path assumptions where impacted.

## Execution Log

### 2026-03-17

- Created this execution plan file and set initial scope rules.
- Baseline: nixosConfigurations attr names = ["iso", "nix-vm", "nix-vmMinimal"].
- Baseline: checks.x86_64-linux attr names = ["bats-test", "pre-commit-check"].
- Baseline: nix-vm toplevel drvPath resolves successfully.
- Implemented: added modules/common/nix.nix (shared Nix policy module) adapted from upstream.
- Implemented: added modules/common/monitors.nix (shared monitor schema) adapted from upstream.
- Implemented: removed duplicated inline nix settings from hosts/common/core/default.nix.
- Implemented: expanded modules/common/host-spec.nix with upstream-compatible architecture-level flags (remote/admin/dev/wayland/x11/theme/default app/timezone) and safety assertion.
- Regression fixed: accidentally removed nixpkgs overlay/allowUnfree block in hosts/common/core/default.nix during refactor; block restored and revalidated.
- Validation: nix-vm toplevel drvPath resolves; checks attr names unchanged.
- Validation: nixosConfigurations attr names unchanged after host-spec expansion.
- Implemented: added nix-index-database flake input and pinned it in flake.lock.
- Implemented: moved disko import ownership from modules/hosts/nixos/disks.nix to hosts/common/core/default.nix.
- Implemented: enabled programs.nix-index-database.comma in core graph, aligned with upstream architecture pattern.
- Implemented: refactored overlays/default.nix to upstream-style named overlay set merged into default overlay.
- Implemented: refactored checks/default.nix to use introdus pre-commit hook abstraction while preserving bats and local hook policy.
- Implemented: aligned shell.nix interface and package layout to upstream conventions while preserving dynamic NIX_SECRETS_DIR portability behavior.
- Validation: nix-vm toplevel drvPath resolves after core wiring changes; checks attr names unchanged.
- Validation: nixosConfigurations/checks eval still stable after overlay and checks refactors.
- Implemented: normalized hosts/common/core/sops.nix comments and structure while retaining shared->host fallback behavior for passwords.
- Validation: impermanence+sops key path for nix-vm evaluates to /persist/etc/ssh/ssh_host_ed25519_key; persistFolder evaluates to /persist for nix-vm and nix-vmMinimal.
- Note: nix-vmMinimal does not expose config.sops by design in its minimal module set, so invariant verification for minimal path used hostSpec/persistFolder and toplevel eval health.
- Implemented: incremental phase-2 convergence by adding namespace+secrets specialArgs and adopting secrets alias in hosts/common/core/default.nix.
- Validation: nix-vm and nix-vmMinimal toplevel drvPath still resolve after specialArgs changes.
- Implemented: migrated flake outputs to flake-parts mkFlake/perSystem architecture while preserving nixosConfigurations, packages, checks, formatter, and devShell outputs.
- Implemented: added flake-parts input and pinned it in flake.lock.
- Regression fixed: overlay recursion introduced in flake-parts eval path due empty linuxModifications overlay touching final attrs; changed to constant empty overlay.
- Implemented: normalized minimal host generation to path-driven host files (host-spec/disks/hardware-configuration) and removed hardcoded minimal installer map from flake.nix.
- Validation: nix-vm and nix-vmMinimal toplevel drvPaths resolve; nixosConfigurations/checks attr names unchanged; devShell output still evaluates.
- Implemented: added docs/upstream-adopted-architecture-decisions.md for adopted upstream architecture decisions.
- Implemented: added docs/upstream-intentional-divergences.md for explicit keep-list divergences.
- Implemented: fixed ISO eval-time timestamp path issue in hosts/nixos/iso/default.nix that broke flake check no-build evaluation.
- Validation: flake check --impure --no-build --keep-going now succeeds (warnings only); iso/nix-vm/nix-vmMinimal drvPath evals succeed.
- Next: optional follow-up is enabling test/check script execution beyond evaluation checks.

## Notes

- Ordering chosen to reduce regression risk: baseline first, shared module primitives before broad flake rewiring.
- Upstream reference repo: ../nix-config-upstream
