# Future Work and Next Steps

This file tracks planned work that is intentionally deferred while bootstrapping and testing in a VM.

## Current Phase

- Install and test this `nix-config` on a new NixOS VM (virt-manager/libvirt with qemu/kvm on Ubuntu).
- Validate host build/switch flow and secrets workflow before touching physical machines.

## Planned Migration (Later)

- Migrate two Ubuntu devices to NixOS:
  - laptop (NVIDIA GPU)
  - desktop (NVIDIA GPU)
- Add host-specific modules for NVIDIA setup and tune per device after VM baseline is stable.

## Impermanence Plan (In Progress)

Goal: ephemeral root filesystem where root state is reset on reboot, while important data persists.

- Current status:
  - reusable impermanence module and btrfs rollback flow are implemented
  - reusable disko layout supports persisted subvolumes and optional LUKS
- Continue validating and refining persistent paths for:
  - system state needed across reboots
  - user state that must survive
  - secrets-related paths and machine identity where required
- Validate reboot behavior and recovery workflow in VM first.

## YubiKey-First Security Plan (In Progress)

Target: use YubiKey broadly across the system while retaining backup access paths.

- Current status:
  - upstream-style reusable host YubiKey module is added (`modules/hosts/common/yubikey.nix`)
  - optional host wrapper is added and enabled on `nix-vm` (`hosts/common/optional/yubikey.nix`)
  - Home Manager YubiKey touch detector module is added and enabled on `nix-vm`
  - home sops module now supports conditional YubiKey U2F/SSH secret extraction when `hostSpec.useYubikey = true`
  - `nix-vm` now enables reusable disko LUKS (`system.disks.useLuks = true`) for full-disk encryption testing
- Remaining rollout work:
  - add/verify required YubiKey entries in `nix-secrets/sops/shared.yaml` (`keys/u2f`, `keys/ssh/<name>`)
  - validate end-to-end login/sudo/lockscreen behavior in VM and tune toggles
  - enroll backup YubiKey(s) before tightening fallback policy

- Full disk encryption (upstream-aligned flow):
  - bootstrap install with passphrase-backed LUKS first
  - after first boot, change temporary passphrase to permanent passphrase
  - enroll YubiKey(s) with FIDO2 (`systemd-cryptenroll --fido2-device=auto <device>`)
  - keep at least one strong fallback passphrase as break-glass access
  - optionally use `scripts/enroll-luks-fido2.sh` as a convenience wrapper for manual enrollment
- Expand YubiKey usage to:
  - user login
  - lockscreen unlock
  - sudo authentication
  - nix-secrets/sops-related access and operational workflows
  - age private key operations for secrets workflows (decrypt/edit/rekey) with YubiKey-backed mechanisms
- Keep non-YubiKey fallback credentials only for recovery scenarios.

## Nix-Secrets Scheme Status

- Current state: this repo is already using a `complex`-style `nix-secrets` layout (`sops/shared.yaml` + per-host files).
- Continue validating key management, creation rules, and rebuild flow in VM before physical hosts.

## Notes

- The upstream `nix-config-starter` does not include full YubiKey glue by default.
- Use the full upstream repo as reference when implementing these modules:
  - https://github.com/EmergentMind/nix-config
- Related upstream guidance from project author:
  - Enroll YubiKey after install and after setting permanent LUKS passphrase.
  - Prefer keeping a fallback passphrase in case key loss/failure.
