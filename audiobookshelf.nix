{...}: {
  services.audiobookshelf = {
    enable = true;
    openFirewall = true;
    dataDir = "/mnt/media/audiobookshelf";
  };
}
