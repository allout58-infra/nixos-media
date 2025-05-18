self: super: {
  libation = super.libation.overrideAttrs (old: rec {
    version = "12.4.3";
    src = super.fetchFromGitHub {
      owner = "rmcrackan";
      repo = "Libation";
      tag = "v${version}";
      hash = "sha256-JJH9u4fAbuIAnnT7de60q0oOhepbloy3eTaUBLuIT7M=";
    };
  });
}
