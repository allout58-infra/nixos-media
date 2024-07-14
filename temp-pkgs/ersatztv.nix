{ config, pkgs, lib, ... }:

let
  inherit (lib) mkIf getExe maintainers mkEnableOption mkOption mkPackageOption;
  inherit (lib.types) str path bool;
  cfg = config.services.ersatztv;
in
{
  options = {
    services.ersatztv = {
      enable = mkEnableOption "ErsatzTV";

      package = mkPackageOption pkgs "ersatztv" { };

      user = mkOption {
        type = str;
        default = "ersatztv";
        description = "User account under which ErsatzTV runs.";
      };

      group = mkOption {
        type = str;
        default = "ersatztv";
        description = "Group under which ErsatzTV runs.";
      };

      transcodeDir = mkOption {
        type = path;
        default = "/var/lib/etv-transcode";
        description = ''
          Temporary transcode directory
        '';
      };

      configDir = mkOption {
        type = path;
        default = "/var/lib/ersatztv";
        description = ''
          Directory containing the server configuration files and SQLite Database file
        '';
      };

      openFirewall = mkOption {
        type = bool;
        default = false;
        description = ''
          Open the default ports in the firewall for the server.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd = {
      tmpfiles.settings.ersatztvDirs = {
        "${cfg.transcodeDir}"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
        "${cfg.configDir}"."d" = {
          mode = "700";
          inherit (cfg) user group;
        };
      };
      services.ersatztv = {
        description = "ErsatzTV";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "simple";
          User = cfg.user;
          Group = cfg.group;
          UMask = "0077";
          WorkingDirectory = cfg.configDir;
          ExecStart = "${getExe cfg.package}";
          Restart = "on-failure";

          # Security options:
          # NoNewPrivileges = true;
          # SystemCallArchitectures = "native";
          # # AF_NETLINK needed because Jellyfin monitors the network connection
          # RestrictAddressFamilies = [ "AF_UNIX" "AF_INET" "AF_INET6" "AF_NETLINK" ];
          # RestrictNamespaces = !config.boot.isContainer;
          # RestrictRealtime = true;
          # RestrictSUIDSGID = true;
          # ProtectControlGroups = !config.boot.isContainer;
          # ProtectHostname = true;
          # ProtectKernelLogs = !config.boot.isContainer;
          # ProtectKernelModules = !config.boot.isContainer;
          # ProtectKernelTunables = !config.boot.isContainer;
          # LockPersonality = true;
          # PrivateTmp = !config.boot.isContainer;
          # # needed for hardware acceleration
          # PrivateDevices = false;
          # PrivateUsers = true;
          # RemoveIPC = true;

          # SystemCallFilter = [
          #   "~@clock" "~@aio" "~@chown" "~@cpu-emulation" "~@debug" "~@keyring" "~@memlock" "~@module" "~@mount" "~@obsolete" "~@privileged" "~@raw-io" "~@reboot" "~@setuid" "~@swap"
          # ];
          # SystemCallErrorNumber = "EPERM";
        };
      };
    };

    users.users = mkIf (cfg.user == "ersatztv") {
      ersatztv = {
        inherit (cfg) group;
        isSystemUser = true;
      };
    };

    users.groups = mkIf (cfg.group == "ersatztv") {
      ersatztv = {};
    };

    networking.firewall = mkIf cfg.openFirewall {
      # from https://ersatztv.org/docs/user-guide/install#manual-installation-2
      allowedTCPPorts = [ 8409 ];
    };

  };

  meta.maintainers = with maintainers; [ allout58 ];
}
