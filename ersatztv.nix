{pkgs-me, ...}: {
  imports = [
    # ./temp-pkgs/ersatztv/package.nix
    ./temp-pkgs/ersatztv.nix
  ];
  services.ersatztv = {
    package = pkgs-me.ersatztv;
    enable = true;
    openFirewall = true;
  };

  environment.systemPackages = [ pkgs-me.ersatztv ];
}
