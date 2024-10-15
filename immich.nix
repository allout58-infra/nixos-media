{pkgs, pkgs-unstable, nixpkgs-unstable, ...}: {
  imports = [
    "${nixpkgs-unstable}/nixos/modules/services/web-apps/immich.nix"
  ];
  # virtualization = {
  #   containers.enable = true;
  #   oci-containers.backend = "podman";
  #   podman = {
  #     enable = true;
  #     dockerCompat = true;

  #     defaultNetwork.settings.dns_enabled = true;
  #   };
  # };

  # environment.systemPackages = with pkgs; [
  #   dive
  #   podman-tui
  #   docker-compose
  #   podman-compose
  # ];
  services.immich = {
    package = pkgs-unstable.immich;
    enable = true;
    environment.IMMICH_MACHINE_LEARNING_URL = "http://localhost:3003";
    openFirewall = true;
    host = "0.0.0.0";
  };

  users.users.immich.extraGroups = ["video" "render"];
}
