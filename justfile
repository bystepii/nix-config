SOPS_FILE := "../nix-secrets/.sops.yaml"

# Define path to helpers
export HELPERS_PATH := env_var('HELPERS_PATH')

# default recipe to display help information
[private]
default:
  @just --list

# Update commonly changing flakes and prep for a rebuild
[private]
rebuild-pre HOST=`hostname`:
  @just lock-init {{HOST}}
  @just update-nix-secrets {{HOST}}
  @git add --intent-to-add .

# Run post-rebuild checks, like if sops is running properly afterwards
[private]
rebuild-post: check-sops

# Run a flake check on the config and installer
[group("checks")]
check HOST=`hostname` ARGS="":
	NIXPKGS_ALLOW_UNFREE=1 REPO_PATH=$(pwd) nix flake check --impure --keep-going --show-trace $( [ -f locks/{{HOST}}.lock ] && echo "--reference-lock-file locks/{{HOST}}.lock" ) {{ARGS}}

# Rebuild the system
[group("building")]
rebuild HOST=`hostname`:
  # NOTE: Add --option eval-cache false if you end up caching a failure you can't get around
  just rebuild-host {{HOST}}
  just rebuild-post

# Rebuild the system and run a flake check
[group("building")]
rebuild-full HOST=`hostname`:
  just rebuild-host {{HOST}}
  just rebuild-post
  just check {{HOST}}

# Rebuild the system and run a flake check
[group("building")]
rebuild-trace HOST=`hostname`:
  just rebuild-host {{HOST}}
  just rebuild-post
  just check {{HOST}} "--show-trace"

# Run remote bootstrap installer flow for a target host
[group("admin")]
bootstrap HOST DESTINATION SSH_KEY ARGS="":
  bootstrap-nixos -n {{HOST}} -d {{DESTINATION}} -k {{SSH_KEY}} {{ARGS}}

# Update the flake
[group("update")]
update HOST=`hostname` *INPUT:
  @if [ -f locks/{{HOST}}.lock ]; then nix flake update {{INPUT}} --timeout 5 --reference-lock-file locks/{{HOST}}.lock --output-lock-file locks/{{HOST}}.lock; else nix flake update {{INPUT}} --timeout 5; fi

# Initialize host lock file from flake.lock if missing
[group("update")]
lock-init HOST=`hostname`:
  @mkdir -p locks
  @if [ ! -f locks/{{HOST}}.lock ]; then cp flake.lock locks/{{HOST}}.lock; fi

# Refresh host lock file from current flake graph
[group("update")]
lock-refresh HOST=`hostname` *INPUT:
  @just lock-init {{HOST}}
  nix flake update {{INPUT}} --timeout 5 --reference-lock-file locks/{{HOST}}.lock --output-lock-file locks/{{HOST}}.lock

# Update and then rebuild
[group("building")]
rebuild-update: update rebuild

# Git diff there entire repo expcept for flake.lock
[group("misc")]
diff:
  git diff ':!flake.lock'

# Generate a new age key
[group("secrets")]
age-key:
  nix-shell -p age --run "age-keygen"

# Check if sops-nix activated successfully
[group("checks")]
check-sops:
  check-sops

# Update nix-secrets flake
[group("update")]
update-nix-secrets HOST=`hostname`:
  @(cd ../nix-secrets && git fetch && git rebase > /dev/null) || true
  @just update {{HOST}} nix-secrets

# Build an iso image for installing new systems and create a symlink for qemu usage
[group("building")]
iso HOST=`hostname`:
  # If we dont remove this folder, libvirtd VM doesnt run with the new iso...
  rm -rf result
  nix build --impure .#nixosConfigurations.iso.config.system.build.isoImage $( [ -f locks/{{HOST}}.lock ] && echo "--reference-lock-file locks/{{HOST}}.lock" ) && ln -sf result/iso/*.iso latest_{{HOST}}.iso

# Install the latest iso to a flash drive
[group("building")]
iso-install DRIVE HOST=`hostname`:
  just iso {{HOST}}
  sudo dd if=$(eza --sort changed result/iso/*.iso | tail -n1) of={{DRIVE}} bs=4M status=progress oflag=sync

# Configure a drive password using disko
[group("misc")]
disko DRIVE PASSWORD:
  echo "{{PASSWORD}}" > /tmp/disko-password
  sudo nix --experimental-features "nix-command flakes pipe-operators" run github:nix-community/disko -- \
    --mode disko \
    disks/btrfs-luks-impermanence-disko.nix \
    --arg disk '"{{DRIVE}}"' \
    --arg password '"{{PASSWORD}}"'
  rm /tmp/disko-password

# Copy all the config files to the remote host
[group("admin")]
sync USER HOST PATH:
	rsync -av --filter=':- .gitignore' -e "ssh -l {{USER}} -oport=22" . {{USER}}@{{HOST}}:{{PATH}}/nix-config

# Run nixos-rebuild on the remote host
[group("admin")]
build-host HOST:
	NIX_SSHOPTS="-p22" nixos-rebuild --target-host {{HOST}} --use-remote-sudo --show-trace --impure --flake .#"{{HOST}}" switch

# Rebuild the specified host from this repository
[group("building")]
rebuild-host HOST=`hostname`:
  @just rebuild-pre {{HOST}}
  @rebuild-host {{HOST}}

# Called by the rekey recipe
[group("secrets")]
sops-rekey:
  cd ../nix-secrets && for file in $(ls sops/*.yaml); do \
    sops updatekeys -y $file; \
  done

# Update all keys in sops/*.yaml files in nix-secrets to match the creation rules keys
[group("secrets")]
rekey: sops-rekey
  cd ../nix-secrets && \
    (pre-commit run --all-files || true) && \
    git add -u && (git commit -nm "chore: rekey" || true) && git push

# Update an age key anchor or add a new one
[group("secrets")]
sops-update-age-key FIELD KEYNAME KEY:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_update_age_key {{FIELD}} {{KEYNAME}} {{KEY}}

# Update an existing user age key anchor or add a new one
[group("secrets")]
sops-update-user-age-key USER HOST KEY:
  just sops-update-age-key users {{USER}}_{{HOST}} {{KEY}}

# Update an existing host age key anchor or add a new one
[group("secrets")]
sops-update-host-age-key HOST KEY:
  just sops-update-age-key hosts {{HOST}} {{KEY}}

# Automatically create creation rules entries for a <host>.yaml file for host-specific secrets
[group("secrets")]
sops-add-host-creation-rules USER HOST:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_add_host_creation_rules "{{USER}}" "{{HOST}}"

# Automatically create creation rules entries for a shared.yaml file for shared secrets
[group("secrets")]
sops-add-shared-creation-rules USER HOST:
    #!/usr/bin/env bash
    source {{HELPERS_PATH}}
    sops_add_shared_creation_rules "{{USER}}" "{{HOST}}"

# Automatically add the host and user keys to creation rules for shared.yaml and <host>.yaml
[group("secrets")]
sops-add-creation-rules USER HOST:
    just sops-add-host-creation-rules {{USER}} {{HOST}} && \
    just sops-add-shared-creation-rules {{USER}} {{HOST}}

# Refresh dev environment with updated inputs
[group("dev")]
dev:
  @just rebuild-pre
  direnv reload

# Format nix code, preferring host lock if present
[group("dev")]
fmt HOST=`hostname`:
  @if [ -f locks/{{HOST}}.lock ]; then nix fmt --reference-lock-file locks/{{HOST}}.lock; else nix fmt; fi
