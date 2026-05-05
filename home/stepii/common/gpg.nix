{ ... }:
{
  programs.gpg = {
    enable = true;
    publicKeys = [
      {
        source = ./gpg-pubkey.asc;
        trust = "ultimate";
      }
    ];

    # Disable scdaemon's internal CCID driver so it uses pcscd exclusively.
    # Without this, scdaemon and pcscd fight over the YubiKey causing 60+
    # second delays on re-insertion before SSH keys become available.
    scdaemonSettings = {
      disable-ccid = true;
    };
  };
}
