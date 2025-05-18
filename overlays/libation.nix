self: super: {
  libation = super.libation.overrideAttrs (old: rec {
    version = "12.4.3";
    src = super.fetchFromGitHub {
      owner = "rmcrackan";
      repo = "Libation";
      tag = "v${version}";
      hash = "sha256-1csgi2xh951ng6vqr5jvxa2hwjmbnkp7byvlkq0f4vn0hyxzv494";
    };
  });
}
