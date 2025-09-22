<div align="center">
<h1>
<img width="100" src="docs/nixos-ascendancy.png" /> <br>
</h1>
</div>

# EmergentMind's Nix-Config Starter

This is a stripped-down, reference version of EmergentMinds's [nix-config](https://github.com/EmergentMind/nix-config) intended to help you set up your own without having to delete all of the personal configurations I use that you may not want.

This repository makes several assumptions as described in the contents below.

Note that my actual nix-config has already deviated from this repository and will continue to do so over time. Depending on how much use this starter repo gets, I may try to keep it updated but there are no guarantees. Please feel free to let me know if you notice any issues or discrepancies. Contributions are welcome.

## Table of Contents

- [How To Use](#how-to-use)
- [Secrets Management](#secrets-management)
- [Installation Steps](#installation-steps)
- [Guidance and Resources](#guidance-and-resources)
- [Support This Project](#support-this-project)
- [Acknowledgements](#acknowledgements)

---

## How To Use

IMPORTANT: For simiplicity, the scripts in this repo assume that it will be cloned to a directory called `nix-config` AND that your `nix-secrets` repo will be in the same parent directory as `nix-config`.
For example:
```
~/src/nix-config
~/src/nix-secrets
```

1. Clone this repo to your local machine and ensure that it is renamed from `nix-config-starter` to `nix-config`
2. Familiarize yourself with both the structure and contents of the repo.
3. Throughout the repository are several `#FIXME(starter)` comments specifically intended to bring your attention to areas that must be edited to suit your needs. Work your way through the repo contents and adjust the contents according to the comments you find.
4. Set up your secrets repository using the resources described in the [Secrets Management](#secrets-management) section below.
    Ensure that your `nix-secrets` repository is created in the same parent directory `nix-config` is located.
5. Build. You can build and switch into this config on a local machine using `just rebuild`
        OR
    If you are installing to a remote target you can use the nixos-installer that is included in the repo. For more information on how this is works is referenced below in the [Installation on Remote Targets](#installation-on-remote-targets) section below.

## Secrets Management

Secrets for this config are stored in a private repository called `nix-secrets` that is pulled in as a flake input and managed using the sops-nix tool.

For details on how this is accomplished, how to approach different scenarios, and troubleshooting for some common hurdles, please see my article and accompanying YouTube video [NixOS Secrets Management](https://unmovedcentre.com/posts/secrets-management/) available on my website. There is also a [nix-secrets-reference](https://github.com/EmergentMind/nix-secrets-reference) repository that can be used in conjunction with the article.

## Installation on Remote Targets

For details on how to use the nixos-installer directory and `scripts/bootstrap-nixos.sh` script, please see my article and accompanying YouTube video [Remotely Installing NixOS and nix-config with Secrets](https://unmovedcentre.com/posts/remote-install-nixos-config/).

## Guidance and Resources

- Watch NixOS related videos on my [YouTube channel](https://www.youtube.com/@Emergent_Mind).
- Chat with me directly on our [Discord server](https://discord.gg/XTFg57xGxC).

- [NixOS.org Manuals](https://nixos.org/learn/)
- [Official Nix Documentation](https://nix.dev)
  - [Best practices](https://nix.dev/guides/best-practices)
- [Noogle](https://noogle.dev/) - Nix API reference documentation.
- [Official NixOS Wiki](https://wiki.nixos.org/)
- [NixOS Package Search](https://search.nixos.org/packages)
- [NixOS Options Search](https://search.nixos.org/options?)
- [Home Manager Option Search](https://home-manager-options.extranix.com/)
- [NixOS & Flakes Book](https://nixos-and-flakes.thiscute.world/) - an excellent introductory book by Ryan Yin

## Support This Project

Sincere thanks to all of my generous supporters!

If you find what I do helpful, please consider supporting my work using one of the links under "Sponsor this project" on the right-hand column of this page.

I intentionally keep all of my content ad-free but some platforms, such as YouTube, put ads on my videos outside of my control.

## Acknowledgements
n
Those who have heavily influenced this strange journey into the unknown.

- [FidgetingBits](https://github.com/fidgetingbits) - You told me there was a strange door that could be opened. I'm truly grateful.
- [Mic92](https://github.com/Mic92) and [Lassulus](https://github.com/Lassulus) - My nix-config leverages many of the fantastic tools that these two people maintain, such as sops-nix, disko, and nixos-anywhere.
- [Misterio77](https://github.com/Misterio77) - Structure and reference.
- [Ryan Yin](https://github.com/ryan4yin/nix-config) - A treasure trove of useful documentation and ideas.
- [VimJoyer](https://github.com/vimjoyer) - Excellent videos on the high-level concepts required to navigate NixOS.

---

[Return to top](#emergentminds-nix-config-starter)
