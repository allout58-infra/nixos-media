{...}: let
  # Shared NFS options for the NAS exports.
  #
  # `nofail` keeps a dead NAS from hanging boot, but on its own it also lets boot
  # continue with the mount silently missing. The 2026-08-27 reboot hit systemd's
  # default 90s mount timeout while the NAS was still coming up, so /mnt/data never
  # mounted and immich-server crash-looped for 16 days. `retry=5` lets mount.nfs keep
  # trying for 5 minutes; the 10 minute unit timeout keeps systemd from killing that
  # retry loop partway through.
  nfsOptions = [
    "auto"
    "nofail"
    "noatime"
    "nolock"
    "intr"
    "tcp"
    "actimeo=1800"
    "retry=5"
    "x-systemd.mount-timeout=10min"
  ];
in {
  fileSystems."/mnt/media" = {
    device = "192.168.2.20:/mnt/tank/media";
    fsType = "nfs";
    options = nfsOptions;
  };
  fileSystems."/mnt/data" = {
    device = "192.168.2.20:/mnt/tank/data";
    fsType = "nfs";
    options = nfsOptions;
  };
}
