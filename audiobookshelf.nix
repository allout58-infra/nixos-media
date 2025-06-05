{pkgs, ...}: {
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
        "/tmp/audiobooks:/data"
      ];
    };
  };

  # Libation had issues pulling directly to the mount point, so we pull to a temporary directory and then move it later
  systemd.services.libation-pull = {
    description = "Pull audiobooks from Libation";
    wants = [ "podman-libation.service" ];
    after = [ "network.target" "podman-libation.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "root";
      ExecStart = "${pkgs.bash}/bin/bash -c 'mv /tmp/audiobooks/* \"/mnt/media/media/Audio Books/\" && rm -rf /tmp/audiobooks/*'";
    };
  };
  systemd.timers.libation-pull = {
    description = "Timer to pull audiobooks from Libation";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
    };
    unitConfig = {
      PartOf = "libation-pull.service";
    };
  };
}
