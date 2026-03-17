# Bootstrap and Remove NixOS Hosts

This guide documents the end-to-end host lifecycle for this repository:

- bootstrap a new host
- initialize and update `nix-secrets` age keys and creation rules
- set password secrets correctly
- remove a host safely

## Assumptions

- Repos are siblings:

```text
/home/<you>/.../nix-config
/home/<you>/.../nix-secrets
```

- You run commands from `nix-config` unless stated otherwise.
- The target host already has a host directory in `hosts/nixos/<host>/`.
- `nixos-installer/flake.nix` contains an entry for the host.

Example in this repo:

- host: `nix-vm`
- user: `stepii`

## Quick Command Index

From `nix-config`:

- `just bootstrap HOST DESTINATION SSH_KEY [ARGS]`
- `./scripts/enroll-luks-fido2.sh /path/to/dev/`
- `just sops-update-user-age-key USER HOST KEY`
- `just sops-update-host-age-key HOST KEY`
- `just sops-add-creation-rules USER HOST`
- `just rekey`
- `just update-nix-secrets`
- `just rebuild`
- `just check`

## Part 1: Bootstrap a New Host

### 1. Prepare host config files

Ensure these exist:

- `hosts/nixos/<host>/default.nix`
- `hosts/nixos/<host>/hardware-configuration.nix`
- `home/<user>/<host>.nix` (if used by your HM layout)

Ensure installer has this host entry:

- `nixos-installer/flake.nix`:
  - `nixosConfigurations.<host> = newConfig "<host>" "<disk>" <swapGiB> <impermanenceBool> <useLuksBool>;`

If the host uses impermanence, set `<impermanenceBool>` to `true`.
If the host uses encrypted root in its main host config, set `<useLuksBool>` to `true` here as well.

### 1a. Impermanence preflight (required for impermanent hosts)

Impermanence hosts require `@persist` to exist from install time. That only happens if
`nixos-installer/flake.nix` enables impermanence for that host entry.

Example:

```nix
nix-vm = newConfig "nix-vm" "/dev/vda" 4 true true;
```

If this is `false` (or omitted in older versions), the install may complete, but the first
`just rebuild` can fail during activation and the next reboot can land in emergency mode.

### 2. Ensure source machine can encrypt/decrypt secrets

Create local user age key if missing:

```bash
mkdir -p ~/.config/sops/age
[ -f ~/.config/sops/age/keys.txt ] || age-keygen -o ~/.config/sops/age/keys.txt
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
```

Get public keys for your source machine user and host:

```bash
USER_AGE_PUB="$(age-keygen -y ~/.config/sops/age/keys.txt)"
SOURCE_HOST="$(hostname)"
SOURCE_HOST_AGE_PUB="$(ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub)"
```

Register them into `../nix-secrets/.sops.yaml`:

```bash
just sops-update-user-age-key stepii "$SOURCE_HOST" "$USER_AGE_PUB"
just sops-update-host-age-key "$SOURCE_HOST" "$SOURCE_HOST_AGE_PUB"
just sops-add-creation-rules stepii "$SOURCE_HOST"
```

### 3. Initialize plaintext example secrets files (first run only)

If `nix-secrets/sops/*.yaml` files are plaintext examples, encrypt them once.

From `nix-secrets`:

```bash
cd ../nix-secrets
sops encrypt --in-place sops/shared.yaml
```

If a host file exists and is plaintext, encrypt it too:

```bash
sops encrypt --in-place sops/<host>.yaml
```

If you see `sops metadata not found`, the file is still plaintext and must be encrypted first.

### 4. Set the user password secret correctly

This config uses `hashedPasswordFile` for user creation, so store a hash (not plaintext).

Generate yescrypt hash:

```bash
PASS_HASH="$(nix shell nixpkgs#whois -c mkpasswd -m yescrypt)"
```

Edit `../nix-secrets/sops/shared.yaml`:

```bash
cd ../nix-secrets
sops sops/shared.yaml
```

Set:

```yaml
passwords:
  stepii: "$y$..."
```

### 5. Rekey and push secrets

From `nix-config`:

```bash
cd ../nix-config
just rekey
just update-nix-secrets
```

### 6. Run bootstrap

Get the target IP from ISO (`ip a` on target), then run:

```bash
just bootstrap nix-vm <TARGET_IP> ~/.ssh/<private_key>
```

Useful optional args:

- `--impermanence`
- `--port <ssh_port>`
- `--luks-secondary-drive-labels "cryptprimary,cryptextra"`

Typical prompt answers for a new host:

1. `Run nixos-anywhere installation?` -> `y`
2. `Manually set luks encryption passphrase?` -> `y` (recommended; set a temporary passphrase if you plan to rotate it post-install)
3. `Generate a new hardware config...?` -> `n` if file already exists, otherwise `y`
4. `Generate host (ssh-based) age key?` -> `y`
5. `Generate user age key?` -> `y`
6. `Copy full nix-config and nix-secrets?` -> `y`
7. `Rebuild immediately?` -> `y` (or `n` if you want to validate `/persist` mount first)

### 6a. Post-install LUKS + YubiKey enrollment (for encrypted hosts)

If the host uses LUKS, finish these steps after first boot.

1. Confirm the device is LUKS2:

```bash
sudo cryptsetup luksDump /path/to/dev/
```

2. If you used a temporary passphrase during bootstrap, rotate it:

```bash
sudo cryptsetup --verbose open --test-passphrase /path/to/dev/
sudo cryptsetup luksChangeKey /path/to/dev/
sudo cryptsetup --verbose open --test-passphrase /path/to/dev/
```

3. Enroll YubiKey(s) for touch-based unlock:

```bash
sudo systemd-cryptenroll --fido2-device=auto /path/to/dev/
```

Repeat enrollment once per key, including backup YubiKey(s).

Optional helper wrapper from `nix-config` root:

```bash
./scripts/enroll-luks-fido2.sh /path/to/dev/
```

Keep at least one strong fallback passphrase enrolled for recovery.

### 7. Validate

```bash
just check-sops
just check
```

For impermanence hosts, also verify persistence paths are mounted and seeded:

```bash
findmnt /persist
ls -l /persist/etc/ssh/ssh_host_ed25519_key
ls -l /persist/etc/machine-id
```

If keys changed and decrypt fails, run `just rekey` again and retry.

## Part 2: Remove a Host Safely

Use this order to avoid breaking decryption for remaining hosts.

### 1. Remove host config files

Delete host files from `nix-config`:

- `hosts/nixos/<host>/`
- `home/<user>/<host>.nix` (if present)

Remove installer entry from `nixos-installer/flake.nix`:

- remove `nixosConfigurations.<host> = newConfig ...`

### 2. Remove host secrets files

Delete host file from `nix-secrets`:

- `sops/<host>.yaml`

### 3. Remove key anchors and creation rules

Edit `nix-secrets/.sops.yaml` and remove:

- host anchor in `keys.hosts`: `&<host>`
- user-host anchor in `keys.users`: `&<user>_<host>`
- `creation_rules` block for `<host>.yaml`
- aliases in `shared.yaml` rule:
  - `*<host>`
  - `*<user>_<host>`

### 4. Re-encrypt remaining files

From `nix-config`:

```bash
just rekey
just update-nix-secrets
```

### 5. Validate no dangling references

```bash
rg "<host>" hosts home nixos-installer
just check
```

Optional local SSH cleanup:

```bash
ssh-keygen -R <host>
ssh-keygen -R <ip>
```

## Troubleshooting

### `sops metadata not found`

Cause:

- file is plaintext and was never encrypted

Fix:

```bash
sops encrypt --in-place <file>
```

### `0 successful groups required, got 0`

Cause:

- `.sops.yaml` recipients changed, but encrypted files were not rekeyed

Fix:

```bash
just rekey
```

### Build cannot find password secret

Cause:

- missing `passwords/<username>` key in secrets

Fix:

- add `passwords.<username>` in `sops/shared.yaml` (or host file, depending on your `sops.nix` logic)
- ensure value is a password hash when using `hashedPasswordFile`

### Reboot drops to emergency mode after impermanence bootstrap

Likely cause:

- host was installed without impermanence enabled in `nixos-installer/flake.nix`
- so the `@persist` subvolume was never created
- later rebuild enabled impermanence and expected `/persist`, causing activation/mount failures
- or installer `useLuks` was `false` while host config expects `system.disks.useLuks = true`, causing boot-time root device mismatch

Fix:

1. Set the host installer entry to use impermanence (`... swapGiB true`).
2. Ensure installer `useLuks` matches the host config (`... true true` for impermanence + LUKS).
3. Reinstall the host (fresh VM is simplest and safest).
4. Bootstrap again using `--impermanence`.
5. Verify `/persist` is mounted before/after the first rebuild.

## Recommended Routine After Any Key Changes

```bash
just rekey
just update-nix-secrets
just check
```
