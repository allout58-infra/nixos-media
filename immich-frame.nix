{...}: {
  virtualisation.oci-containers.containers = {
    immich-frame = {
      image = "ghcr.io/immichframe/immichframe:latest";
      autoStart = true;
      ports = [
        "0.0.0.0:8080:8080"
      ];
      environment = {
        TZ = "America/New_York";
      };
      volumes = [
        "/opt/immich-frame:/app/Config"
      ];
    };
  };

  # This bind-mount source was previously created by hand and existed nowhere in
  # the config. Declare it so a fresh install (or an accidental removal) does not
  # leave podman failing on a missing statfs target.
  systemd.tmpfiles.settings.immich-frame = {
    "/opt/immich-frame"."d" = {
      mode = "755";
      user = "root";
      group = "root";
    };
  };

  networking.firewall.allowedTCPPorts = [8080];
}
