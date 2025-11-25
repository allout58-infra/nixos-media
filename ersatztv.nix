{...}: {
  imports = [
    ./temp-pkgs/ersatztv.nix
  ];
  services.ersatztv = {
    enable = true;
    openFirewall = true;
  };
}
