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
  networking.firewall.allowedTCPPorts = [8080];
}
