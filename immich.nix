{...}: {
  services.immich = {
    # package = pkgs-unstable.immich;
    enable = true;
    environment.IMMICH_MACHINE_LEARNING_URL = "http://localhost:3003";
    openFirewall = true;
    host = "0.0.0.0";
    mediaLocation = "/mnt/data/pictures";
  };

  users.users.immich.extraGroups = ["video" "render"];
}
