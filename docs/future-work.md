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

## Impermanence Plan (Later)

Goal: ephemeral root filesystem where root state is reset on reboot, while important data persists.

- Add an impermanence-capable disk layout (likely btrfs + persisted subvolumes).
- Define explicit persistent paths for:
  - system state needed across reboots
  - user state that must survive
  - secrets-related paths and machine identity where required
- Validate reboot behavior and recovery workflow in VM first.

## YubiKey-First Security Plan (Later)

Target: use YubiKey broadly across the system while retaining backup access paths.

- Full disk encryption:
  - initialize LUKS with passphrase first
  - enroll YubiKey(s) with FIDO2 (`systemd-cryptenroll --fido2-device=auto <device>`)
  - keep at least one strong fallback passphrase as break-glass access
- Expand YubiKey usage to:
  - user login
  - lockscreen unlock
  - sudo authentication
  - nix-secrets/sops-related access and operational workflows
- Keep non-YubiKey fallback credentials only for recovery scenarios.

## Notes

- The upstream `nix-config-starter` does not include full YubiKey glue by default.
- Use the full upstream repo as reference when implementing these modules:
  - https://github.com/EmergentMind/nix-config
- Related upstream guidance from project author:
  - Enroll YubiKey after install and after setting permanent LUKS passphrase.
  - Prefer keeping a fallback passphrase in case key loss/failure.
