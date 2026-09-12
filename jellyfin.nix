{
  pkgs,
  pkgs-old,
  pkgs-jf-pin,
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
      libva-vdpau-driver
      libvdpau-va-gl
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      # vpl-gpu-rt # QSV on 11th gen or newer
      pkgs-old.intel-media-sdk # QSV up to 11th gen
      # using pkgs-old because the unstable version isn't being built, probably because it's insecure
    ];
  };

  # 2. enable jellyfin
  services.jellyfin = {
    # TEMPORARY (Phase 3): pinned to pre-12.0 while Immich 3 soaks. Remove in Phase 4.
    package = pkgs-jf-pin.jellyfin;
    enable = true;
    openFirewall = true;
  };
  services.seerr = {
    enable = true;
    openFirewall = true;
  };
  environment.systemPackages = with pkgs; [
    # TEMPORARY (Phase 3): keep CLI tools in step with the pinned server.
    pkgs-jf-pin.jellyfin
    pkgs-jf-pin.jellyfin-web
    pkgs-jf-pin.jellyfin-ffmpeg
    seerr
    intel-gpu-tools # for verifying hardware acceleration
    libva-utils
  ];
}
