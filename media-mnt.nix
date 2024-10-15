{
  fileSystems."/mnt/media" = {
    device = "192.168.2.20:/mnt/tank/media";
    fsType = "nfs";
    options = ["auto" "nofail" "noatime" "nolock" "intr" "tcp" "actimeo=1800"];
  };
  fileSystems."/mnt/data" = {
    device = "192.168.2.20:/mnt/tank/data";
    fsType = "nfs";
    options = ["auto" "nofail" "noatime" "nolock" "intr" "tcp" "actimeo=1800"];
  };
}
