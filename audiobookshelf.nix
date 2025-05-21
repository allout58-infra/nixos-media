{...}: {
  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };

  virtualisation.oci-containers.containers = {
    libation = {
      image = "docker.io/rmcrackan/libation:latest";
      autoStart = true;
      environment = {
        SLEEP_TIME = "1h";
      };
      volumes = [
        "/var/lib/libation:/config"
        "/mnt/media/media/Audio\ Books:/data"
      ];
      user = "root:root";
    };
  };
}
