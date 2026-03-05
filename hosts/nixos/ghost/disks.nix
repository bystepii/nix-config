{ ... }:
{
  system.disks = {
    # 1TB /dev/nvme0n1
    primary = "/dev/disk/by-id/nvme-WDS100T3XHC-00SJG0_201274802169";
    primaryLabel = "cryptprimary";
    bootSize = "1G";
    useLuks = true;
    extraDisks = [
      {
        # 250GB /dev/nvme1n1
        name = "cryptextra";
        path = "/dev/disk/by-id/nvme-WDS250G3X0C-00SJG0_202604A00429";
      }
      {
        # 500GB /dev/sda
        name = "cryptvms";
        path = "/dev/disk/by-id/ata-WDC_WDS500G2B0A-00SM50_201723800798";
      }
    ];
  };
}
