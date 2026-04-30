# Nix-Config Customization Guide

## 1. Architecture Overview

```
flake.nix
├── hosts/
│   ├── common/core/          # Core system modules (sops, nix, users, boot)
│   ├── common/optional/      # System feature modules (ssh, yubikey, gaming, etc)
│   ├── common/users/         # User definitions (passwords, SSH keys, groups)
│   └── nixos/<hostname>/     # Per-host config (disks, networking, hardware)
├── home/
│   ├── common/core/          # Core home-manager (shell, git, neovim, etc)
│   ├── common/optional/      # Optional HM modules (desktop, browsers, tools)
│   └── <user>/               # Per-user per-host entrypoints
├── modules/
│   ├── hosts/common/         # Reusable NixOS modules (host-spec, yubikey)
│   ├── hosts/nixos/          # Reusable NixOS modules (disks, wifi, backup)
│   └── home/                 # Reusable HM modules (ssh, starship, firefox)
├── overlays/                 # Package overrides
├── pkgs/                     # Custom packages
└── nix-secrets/ (external)   # SOPS secrets, private data
```

**Key principle:** `hostSpec` is the central source of truth. Many modules check `hostSpec` flags to auto-configure. Per-host configs set these flags; modules react.

---

## 2. Host-Spec Options (`modules/hosts/common/host-spec.nix`)

Set these in `hosts/nixos/<host>/host-spec.nix` to control behavior across the entire config.

### Identity & Users
| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `hostName` | str | required | Hostname |
| `primaryUsername` | str | required | Main admin user |
| `primaryDesktopUsername` | str | `primaryUsername` | Desktop session user |
| `users` | [str] | `[primaryUsername]` | All users on host |
| `handle` | str | required | GitHub-style handle |
| `userFullName` | str | required | Full name (git, mail) |
| `domain` | str | `"local"` | Domain for mail, DNS |
| `home` | str | `/home/<user>` | Home directory path |

### Host Type Flags
| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `isMinimal` | bool | `false` | Installer/rescue mode (no HM, no secrets) |
| `isImpermanent` | bool | `false` | **Impermanence** — root on tmpfs, `/persist` for state |
| `isProduction` | bool | `true` | Production tools (copyq, strace, steam-run) |
| `isServer` | bool | `false` | Skip GUI/desktop packages |
| `isDevelopment` | bool | `false` | Dev mode for neovim (hot-reload paths) |
| `isIntrodusDev` | bool | `isDevelopment` | Uses local introdus path instead of git |
| `isWork` | bool | `false` | Work git repos/servers, work SSH keys |
| `isAdmin` | bool | `false` | Admin hosts get extra SSH keys |
| `isRemote` | bool | `false` | Remotely managed hosts |
| `isRoaming` | bool | `false` | Laptop — battery, wifi roaming |
| `isLocal` | bool | `!isRemote` | Inverse of isRemote |

### Hardware & Display
| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `useWayland` | bool | `false` | Wayland session variables, compositors |
| `useX11` | bool | auto | Xorg display |
| `useWindowManager` | bool | `true` | Display manager, keyring, WM packages |
| `defaultDesktop` | str | `"niri"` | Session name for display manager |
| `scaling` | str | `"1"` | HiDPI scale factor |
| `hdr` | bool | `false` | HDR display support |
| `wifi` | bool | `false` | Host has wireless |
| `voiceCoding` | bool | `false` | Talon voice coding (blocks Wayland) |

### Features
| Option | Type | Default | Purpose |
|--------|------|---------|---------|
| `useYubikey` | bool | `false` | YubiKey PAM, udev, SSH key linking |
| `useNeovimTerminal` | bool | `false` | Neovim as terminal editor |
| `isAutoStyled` | bool | `false` | Stylix theming across system |
| `theme` | str | `"dracula"` | Theme name for stylix/apps |
| `wallpaper` | path | nix-assets | Default wallpaper |
| `defaultBrowser` | str | `"firefox"` | Default browser command |
| `defaultEditor` | str | `"nvim"` | Default editor command |
| `defaultMediaPlayer` | str | `"vlc"` | Default video player |
| `useAtticCache` | bool | `true` | LAN binary cache |
| `timeZone` | str | `"America/Edmonton"` | System timezone |
| `persistFolder` | str/null | `null` | Path for impermanence persistence |

### Assertions (enforced at build time)
- `isWork` → must have `work` attribute set in secrets
- `isImpermanent` → `persistFolder` must be non-empty
- `voiceCoding && useWayland` → **forbidden** (Talon doesn't support Wayland)
- `primaryUsername` must exist in `users` list

---

## 3. System-Level Optional Modules (`hosts/common/optional/`)

Import any of these in your host's `default.nix` to enable features.

### Security & Access
- **`yubikey.nix`** — Sets `yubikey.enable = true` and defines identifiers (serial numbers). Enables PAM u2f for login/sudo, udev rules for SSH key linking on insert/remove, yubikey-manager, yubioath-flutter.
- **`services/openssh.nix`** — Hardened SSH: no passwords, no root login, persistent host keys in `/persist`, YubiKey PAM rssh for sudo. Firewall opens port from `hostSpec.networking.ports.tcp.ssh`.

### Desktop & GUI
- **`gnome.nix`** — GNOME desktop with stripped default apps. Disables tty1 getty for autologin.
- **`thunar.nix`** — Thunar file manager + gvfs/udisks2/tumbler for mounting and thumbnails.
- **`fonts.nix`** — System-wide font packages (Noto, Source, Nerd Fonts, Font Awesome).
- **`obsidian.nix`** — Obsidian note app (unstable).
- **`vlc.nix`** — VLC media player.

### Hardware
- **`amdgpu_top.nix`** — AMD GPU monitoring tool.
- **`nvtop.nix`** — GPU monitor for AMD/Intel.
- **`scanning.nix`** — SANE scanning backends (Samsung, HP, AirScan) + simple-scan.
- **`zsa-keeb.nix`** — ZSA keyboard support + keymapp flashing tool.

### Gaming
- **`gaming.nix`** — Steam (with Proton-GE, protontricks), GameMode performance tuning, lsfg-vk frame generation.

### Networking & VPN
- **`protonvpn.nix`** — ProtonVPN GUI client.
- **`libvirt.nix`** — QEMU/KVM + virt-manager. Defines NAT network `vm-lan`. Adds user to `libvirtd` group.
- **`nfs-ghost-mediashare.nix`** — NFS automount from `ghost` host (hardcoded to upstream's network).

### Services
- **`services/printing.nix`** — CUPS with Samsung drivers.
- **`services/ollama.nix`** — Ollama LLM server with ROCm GPU + preloads `qwen2.5-coder:32b`.
- **`services/logrotate.nix`** — Logrotate service.

### Mail
- **`mail-delivery.nix`** — Local SMTP via `introdus.mail-delivery`. Sends directly (no relay). Uses `hostSpec.email` for server selection.

### Minimal / Install
- **`minimal-configuration.nix`** — Bare installer config. Used by `mkMinimalHost` automatically. Sets `isMinimal = true`.
- **`minimal-user.nix`** — Temporary user with pre-hashed password for ISO builds.

---

## 4. NixOS Reusable Modules (`modules/hosts/nixos/`)

These are automatically imported via `modules/hosts/nixos/default.nix` (scanPaths). They expose options you can set in host configs.

### `disks.nix` — Disko + LUKS + Impermanence
**Options under `system.disks`:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `true` | Use disko templates |
| `primary` | str | required | Disk path (e.g. `/dev/vda`) |
| `primaryDiskoLabel` | str | `"primary"` | Disk label prefix |
| `luks.enable` | bool | `true` | LUKS encryption |
| `luks.label` | str | `"encrypted-nixos"` | LUKS container name |
| `swapSize` | str/null | `null` | Swap size (e.g. `"2G"`) |
| `bootSize` | str/null | `"512M"` | EFI partition size |
| `raidDisks` | [str]/null | `null` | mdadm RAID disks |
| `raidLevel` | int | `5` | RAID level |
| `extraDisks` | [{name path}]/null | `null` | Secondary LUKS disks |
| `raidMountPath` | str | `"/mnt/storage"` | RAID mountpoint |

**Btrfs subvolumes created:**
- `@root` → `/`
- `@nix` → `/nix`
- `@persist` → `/persist` (only if `hostSpec.isImpermanent`)
- `@swap` → swapfile (if `swapSize` set)

### `wifi.nix` — NetworkManager WiFi via SOPS
**Options under `wifi`:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable WiFi management |
| `roaming` | bool | false | Use ALL wifi networks from secrets |
| `wlans` | [str] | `[]` | Specific WLAN names to use |
| `disableWhenWired` | bool | false | Turn off WiFi when ethernet connects |

**Secrets:** Place `wifi.<wlan>.yaml` files in `nix-secrets/sops/`. Each contains AP names and passwords. SOPS generates NetworkManager `nmconnection` files.

### `backup/default.nix` — BorgBackup
**Options under `services.backup`:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable borg backups |
| `borgServer` | str | `"oath"` | Remote borg host |
| `borgPort` | str | ssh port | SSH port for borg |
| `borgBackupPath` | str | `"/volume1/backups"` | Remote path |
| `borgBackupPaths` | [str] | `[home]` | Paths to backup |
| `borgBackupStartTime` | str | `"00:00:00"` | Daily backup time |
| `borgExcludes` | [str] | `[]` | Extra exclude paths |

Provides CLI tools: `borg-backup-init`, `borg-backup-list`, `borg-backup-mount`, `borg-backup-restore`, etc.

### `autossh-tunnels/default.nix` — Reverse SSH Tunnels
**Options under `autossh-tunnels`:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable autossh tunnels |
| `sessions` | attrs | `{}` | Per-tunnel config (remote port, local port, host, user) |

### `battery-power.nix`
**Options under `batteryPowerServices`:**
| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | false | Enable upower + power-profiles-daemon |

### `remote-luks-unlock/default.nix` — Initrd SSH Unlock
Enables dropbear in initrd for remote LUKS unlock. See module for options.

### `ups.nix` — NUT UPS client
Connects to network UPS. Uses `hostSpec.networking` for server IP.

---

## 5. Home-Manager Customization

### Entrypoint: `home/<user>/<hostname>.nix`

This is where you compose a user's home config for a specific host.

```nix
{ lib, ... }:
{
  imports = map lib.custom.relativeToRoot (
    [
      "home/common/core"          # ALWAYS include
      "home/<user>/common"        # User-specific common config
    ]
    ++ map (f: "home/common/optional/${f}") [
      # Pick optional modules for this host/user
      "desktops/niri"
      "sops.nix"
      "development"
      "tools"
    ]
  );
}
```

### Core Modules (`home/common/core/`)
Always imported. These configure baseline tools.

| Module | What it does |
|--------|--------------|
| `zsh/` | Zsh + oh-my-zsh + plugins (zoxide, fzf, vi-mode, autols, color-ssh-nvim-term) + extensive aliases |
| `git.nix` | Git with delta pager, color-conventional-commits |
| `neovim.nix` | Neovim via `introdus.neovim` + `emergentvim` wrapper. Dev mode enables hot-reload |
| `direnv.nix` | direnv + nix-direnv (unstable) |
| `btop.nix` | btop system monitor (gruvbox_dark, vim keys) |
| `bat.nix` | bat + bat-extras with syntax cache rebuild hook |
| `starship.nix` | Starship prompt (unstable) |
| `ghostty.nix` | Ghostty terminal with minimal keybindings |
| `bash.nix` | Bash fallback config |
| `screen.nix` | GNU screen |
| `ssh.nix` | SSH client with default config disabled, placeholder dirs |
| `nixos.nix` | Linux-specific: Wayland env vars, ssh-agent, systemd user services, steam-run, font cache reload |
| `timers/trash-empty.nix` | Weekly trash-empty timer |

### Optional Modules (`home/common/optional/`)

#### Desktop / Compositors
| Module | What it does | Needs |
|--------|--------------|-------|
| `desktops/niri/` | Niri Wayland compositor config (KDL assembly) | `useWayland = true` |
| `desktops/gnome/` | GNOME dconf settings, extensions, scaling | GNOME host module |
| `desktops/noctalia.nix` | Noctalia desktop shell (bar, dock, launcher, OSD) | `stylix` |
| `desktops/services/kanshi.nix` | Dynamic monitor profiles | — |

#### Browsers
| Module | What it does |
|--------|--------------|
| `extrabrowsers/brave.nix` | Brave browser (unstable) |
| `extrabrowsers/chromium.nix` | Chromium with Wayland fixes |

#### Terminal / Multiplexer
| Module | What it does |
|--------|--------------|
| `zellij/` | Zellij terminal multiplexer (KDL config, aliases) |
| `kitty.nix` | Kitty terminal |
| `yazi.nix` | Yazi file manager |

#### Communication
| Module | What it does |
|--------|--------------|
| `comms/default.nix` | Signal (introdus), Discord |
| `networking/protonvpn.nix` | ProtonVPN GUI + alias |

#### Development
| Module | What it does | Secrets |
|--------|--------------|---------|
| `development/default.nix` | gdb, act, gh, glab, nixpkgs-review, nmap, delta, difftastic, devenv, mob | No |
| `development/git.nix` | Advanced git: difftastic, binary diffs, introdus.gitDev | `secrets.git.repos`, `secrets.work.git.servers` |
| `development/aws.nix` | awscli2, cfn-lint | No |
| `development/edu.nix` | bootdev-cli | No |

#### Tools & Media
| Module | What it does |
|--------|--------------|
| `tools/default.nix` | drawio, libreoffice, zola, audacity, gimp, inkscape, obs-studio, blender |
| `media.nix` | ffmpeg, spotify, vlc/mpv |
| `ebooks.nix` | calibre |
| `gaming/default.nix` | Gamescope Steam wrapper (mostly commented) |
| `helper-scripts/` | Custom scripts (copy-github-subfolder, linktree) |

#### Secrets & Auth
| Module | What it does | Secrets |
|--------|--------------|---------|
| `sops.nix` | HM-level sops: age key, nix token, u2f keys, SSH keys | `tokens/nix-access-tokens`, `keys/u2f`, `keys/ssh/*` |
| `atuin.nix` | Shell history sync | `keys/atuin` |

#### Other
| Module | What it does |
|--------|--------------|
| `introdus-xdg.nix` | XDG file associations (CSV → LibreOffice Calc + nvim) |

---

## 6. Introdus Module Options

`introdus` provides several HM/NixOS modules used throughout:

### `introdus.neovim` (`home/common/core/neovim.nix`)
```nix
introdus.neovim = {
  enable = true;
  package = pkgs.emergentvim;  # or pkgs.neovim-unwrapped
  hotReload = {
    enable = osConfig.hostSpec.isIntrodusDev;
    configPath = "~/src/nix/neovim/nvim";
  };
};
```

### `introdus.gitDev` (`home/common/optional/development/git.nix`)
```nix
introdus.gitDev = {
  enable = true;
  keysPath = "~/.ssh";
  devFolders = [ "~/src" ];
  devKeys = [ "id_ed25519" ];
  workFolders = lib.optionals osConfig.hostSpec.isWork [ "~/work" ];
  workKeys = lib.optionals osConfig.hostSpec.isWork [ "id_work" ];
};
```

### `introdus.xdg` (`home/common/optional/introdus-xdg.nix`)
```nix
introdus.xdg = {
  enable = true;
  csvAssociations = [ libreoffice-calc nvim ];
};
```

### `introdus.signal` (`home/common/optional/comms/default.nix`)
```nix
introdus.signal.enable = true;
```

### `introdus.color-conventional-commits` (`home/common/core/git.nix`)
```nix
introdus.color-conventional-commits = {
  enable = true;
  package = pkgs.git;
};
```

### `introdus.mail-delivery` (`hosts/common/optional/mail-delivery.nix`)
System-level module for local SMTP delivery.

---

## 7. Secrets Management

Secrets live in the separate `nix-secrets` flake input.

### Structure
```
nix-secrets/
├── .sops.yaml          # Age key anchors + creation rules
├── sops/
│   ├── shared.yaml     # Shared secrets (passwords, tokens, keys)
│   ├── <hostname>.yaml # Host-specific secrets
│   └── wifi.<wlan>.yaml # WiFi AP credentials
└── nix/
    ├── personal.nix    # domain, email, userFullName
    ├── network.nix     # subnets, hosts, ports, ssh blocks
    ├── development.nix # git repos, work servers
    └── ...
```

### Required Secrets for nix-vm

**`sops/shared.yaml`** must contain:
```yaml
passwords:
  stepii: <hashed-password>   # For user login
keys:
  age: <private-age-key>      # For HM sops decryption
tokens:
  nix-access-tokens: github.com=<pat>
```

**`sops/nix-vm.yaml`** must contain:
```yaml
keys:
  age: <host-age-key>
  ssh:
    host_ed25519: <private-key>
```

### Adding a New Secret
1. Edit the appropriate `.yaml` file: `sops sops/shared.yaml`
2. Reference it in nix-config via `config.sops.secrets."<path>"`
3. If adding a new file, add creation rules to `.sops.yaml`

### Age Keys
- **Host key**: `cat /etc/ssh/ssh_host_ed25519_key.pub | ssh-to-age`
- **User key**: `age-keygen -o ~/.config/sops/age/keys.txt`

---

## 8. YubiKey Setup

### Current Config (`hosts/common/optional/yubikey.nix`)
```nix
{
  yubikey = {
    enable = true;
    identifiers.stepii = 19717214;
  };
}
```

### What This Enables
1. **PAM u2f** — Passwordless login and sudo (touch YubiKey)
2. **udev rules** — Auto-link SSH key on insert, unlink on remove
3. **Packages** — `yubikey-manager`, `yubioath-flutter`, `gnupg`, `pam_u2f`
4. **pcscd** — Smartcard daemon for GPG/OpenPGP

### SSH Key Linking
Place your YubiKey-associated public keys in `~/.ssh/yubikeys/`. On insert, the udev script symlinks the matching key to `~/.ssh/id_yubikey`.

### LUKS + YubiKey (initrd unlock)
The current setup uses **passphrase-only LUKS**. For YubiKey initrd unlock:
```bash
# After first install, enroll FIDO2:
systemd-cryptenroll --fido2-device=auto /dev/vda2
```
Then set `boot.initrd.systemd.enable = true` (already done) and add `fido2` to `boot.initrd.systemd.packages`.

---

## 9. Common Customization Patterns

### Add a New Host
1. `mkdir hosts/nixos/<newhost>`
2. Create `host-spec.nix`, `disks.nix`, `default.nix`, `network.nix`
3. `hosts/common/users/<user>/` if new user
4. `home/<user>/<newhost>.nix` for HM config
5. Add host age key to `nix-secrets/.sops.yaml`
6. Create `nix-secrets/sops/<newhost>.yaml`
7. `nix flake update nix-secrets`
8. `just check <newhost>`

### Add a Desktop Environment
1. In host `default.nix`, import optional modules:
   ```nix
   ++ (map (f: "hosts/common/optional/${f}") [
     "fonts.nix"
     "thunar.nix"
   ])
   ```
2. In user HM config, import desktop modules:
   ```nix
   ++ map (f: "home/common/optional/${f}") [
     "desktops/niri"
     "desktops/noctalia.nix"
   ]
   ```
3. Set hostSpec: `useWayland = true;`, `isAutoStyled = true;`

### Enable WiFi
1. Host `host-spec.nix`: `wifi = true;`
2. Host `default.nix`: import `modules/hosts/nixos/wifi.nix` (or add to auto-imports)
3. Set `wifi.enable = true; wifi.wlans = [ "home" ];`
4. Create `nix-secrets/sops/wifi.home.yaml` with AP credentials

### Enable Backup
1. Host `default.nix`:
   ```nix
   services.backup = {
     enable = true;
     borgServer = "backup.example.com";
     borgBackupPaths = [ "/home/stepii" ];
   };
   ```
2. Add `passwords/borg` to `sops/shared.yaml`

### Customize Disks
Edit `hosts/nixos/<host>/disks.nix`:
```nix
{
  system.disks = {
    primary = "/dev/nvme0n1";
    bootSize = "1G";
    swapSize = "8G";
    luks.label = "cryptprimary";
    extraDisks = [
      { name = "cryptdata"; path = "/dev/disk/by-id/...-part1"; }
    ];
  };
}
```

### Add a Custom Package Overlay
Edit `overlays/default.nix` to add package overrides or new packages.

---

## 10. Files You Will Edit Most Often

| File | Purpose |
|------|---------|
| `hosts/nixos/<host>/host-spec.nix` | Host identity, flags, capabilities |
| `hosts/nixos/<host>/default.nix` | Host system config, module imports |
| `hosts/nixos/<host>/disks.nix` | Disk layout, LUKS, swap |
| `home/<user>/<host>.nix` | Per-user per-home config |
| `hosts/common/users/<user>/` | User definition, SSH keys, groups |
| `nix-secrets/sops/*.yaml` | Passwords, tokens, keys |
| `nix-secrets/.sops.yaml` | Encryption key rules |

---

## 11. Quick Reference: Building & Checking

```bash
# Enter dev shell (has just, sops, age, etc.)
nix develop

# Check config for host
just check nix-vm

# Rebuild local host
just rebuild nix-vm

# Format all files
nix fmt

# Update flake inputs
just update nix-vm nix-secrets

# Add host to sops
just sops-add-creation-rules stepii nix-vm
```
