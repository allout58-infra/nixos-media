{pkgs, ...}: {
  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    host = "0.0.0.0";
  };
  environment.systemPackages = [pkgs.libation];
}
