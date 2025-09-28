{
  pkgs,
  pkgs-old,
  ...
}: {
  # 1. enable vaapi on OS-level
  nixpkgs.config = {
    packageOverrides = pkgs: {
      vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
    };
    permittedInsecurePackages = ["intel-media-sdk-23.2.2"]; # needed for QSV on 11th gen or older, and no upgrade is available
  };
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver # previously vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      # vpl-gpu-rt # QSV on 11th gen or newer
      pkgs-old.intel-media-sdk # QSV up to 11th gen
      # using pkgs-old because the unstable version isn't being built, probably because it's insecure
    ];
  };

  # 2. enable jellyfin
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };
  environment.systemPackages = with pkgs; [
    jellyfin
    jellyfin-web
    jellyfin-ffmpeg
    jellyseerr
    intel-gpu-tools # for verifying hardware acceleration
    libva-utils
  ];
}
