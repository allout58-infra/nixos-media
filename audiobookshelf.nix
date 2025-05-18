{pkgs, ...}: {
  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };
  nixpkgs.overlays = [
    (import ./overlays/libation.nix)
  ];
  environment.systemPackages = [pkgs.libation];

  systemd.services.libation = {
    description = "Libation";
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      User = "libation";
      Group = "libation";
    };
    script = ''
      #!/usr/bin/env bash
      set -euo pipefail
      exec ${pkgs.libation}/bin/libationcli scan
      exec ${pkgs.libation}/bin/libationcli liberate
    '';
  };
  systemd.timers.libation = {
    description = "Libation Timer";
    wantedBy = ["timers.target"];
    timerConfig = {
      OnCalendar = "*-*-* *:00:00";
      Persistent = true;
      Unit = "libation.service";
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
