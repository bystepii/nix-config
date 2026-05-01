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
  };
}
