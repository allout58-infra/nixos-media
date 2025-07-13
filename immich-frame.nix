{...}: {
  virtualisation.oci-containers.containers = {
    immich-frame = {
      image = "ghcr.io/immichframe/immichframe:latest";
      autoStart = true;
      environment = {
        TZ = "America/New_York";
      };
      volumes = [
        "/opt/immich-frame:/app/Config"
      ];
    };
  };
}
