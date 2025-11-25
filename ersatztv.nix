{...}: {
  services.ersatztv = {
    enable = true;
    openFirewall = true;
    environment = {
      ETV_BASE_URL = "/";
      ETV_UI_PORT = 8409;
    };
  };
}
