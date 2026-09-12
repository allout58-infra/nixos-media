{lib, ...}: {
  services.immich = {
    # package = pkgs-unstable.immich;
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/data/pictures";
    accelerationDevices = ["/dev/dri/renderD128"];
  };

  # mediaLocation lives on the NAS over NFS, so immich-server must not start until
  # that mount is actually up. Without this it starts regardless, fails the folder
  # check, and restarts forever -- it reached 153914 restarts over 16 days in 2026-08.
  # The start limit turns that runaway into a clean `failed` state we can actually see.
  systemd.services.immich-server = {
    unitConfig = {
      RequiresMountsFor = "/mnt/data/pictures";
      StartLimitIntervalSec = 300;
      StartLimitBurst = 5;
    };
    # Module default is 3s; 30s spreads the 5 allowed attempts over ~2.5min,
    # which tolerates a brief NFS stall instead of burning the budget in seconds.
    serviceConfig.RestartSec = lib.mkForce 30;
  };
}
