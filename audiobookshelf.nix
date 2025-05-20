{...}: {
  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };

  virtualisation.oci-containers.containers = {
    libation = {
      image = "rmcrackan/libation:latest";
      autoStart = true;
      environment = {
        SLEEP_TIME = "1h";
      };
      volumes = [
        "/var/lib/libation:/config"
        "/mnt/media/media/Audio\ Books:/data"
      ];
      user = "libation:libation";
    };
  };

  users.users.libation = {
    isSystemUser = true;
    home = "/var/lib/libation";
    createHome = true;
    group = "libation";
  };
  users.groups.libation = {
  };
}
