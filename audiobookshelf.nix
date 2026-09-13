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
        "/tmp/audiobooks:/data"
      ];
    };
  };

  # /tmp is cleared on boot, which removes the bind-mount source out from under
  # the libation container. The service below re-creates it too, but the
  # container starts independently and needs it to already exist.
  systemd.tmpfiles.settings.libation = {
    "/tmp/audiobooks"."d" = {
      mode = "775";
      user = "root";
      group = "root";
    };
  };

  # Libation had issues pulling directly to the mount point, so we pull to a temporary directory and then move it later
  systemd.services.libation-pull = {
    description = "Pull audiobooks from Libation";
    wants = ["podman-libation.service"];
    after = ["network.target" "podman-libation.service"];
    # Without this, a NAS mount that is down means moving books into the empty
    # local mountpoint instead of the NAS -- silent misplacement, not a failure.
    unitConfig.RequiresMountsFor = "/mnt/media";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = false;
      User = "root";
    };
    # `nullglob` makes "no new books" a success. Without it the unmatched glob was
    # passed to mv literally, mv exited non-zero, and the && chain left this unit
    # `failed` every hour -- 358 failures between 2026-09-05 and 2026-09-12.
    script = ''
      shopt -s nullglob
      books=(/tmp/audiobooks/*)
      if [ ''${#books[@]} -eq 0 ]; then
        echo "No new audiobooks to move."
        exit 0
      fi
      mv -- "''${books[@]}" "/mnt/media/media/Audio Books/"
      echo "Moved ''${#books[@]} item(s) to the audiobook library."
    '';
  };
  systemd.timers.libation-pull = {
    description = "Timer to pull audiobooks from Libation";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "5min";
      OnUnitActiveSec = "1h";
      Unit = "libation-pull.service";
    };
  };
}
