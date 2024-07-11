{config, ...}: {
  config = {
    security.acme = {
      acceptTerms = true;
      defaults.email = "jamesthollowell@gmail.com";
      certs = let cloudflare_dns_chalenge = {
        dnsProvider = "cloudflare";
        environmentFile = config.age.secrets."cloudflare-dns-challenge".path;
      }; in {
        "jellyfin.home.jameshollowell.com" = cloudflare_dns_chalenge;
        "jellyseerr.home.jameshollowell.com" = cloudflare_dns_chalenge;
      };
      # Temporarily use staging server for testing.
      defaults.server = "https://acme-staging-v02.api.letsencrypt.org/directory";
    };

    services.nginx = {
      enable = true;
      virtualHosts = let
        SSL = {
          addSSL = true;
          enableACME = true;
        };
      in {
        "jellyfin" =
          SSL
          // {
            locations."/".proxyPass = "http://localhost:8096";
            serverAliases = ["jellyfin.home.jameshollowell.com"];
          };
        "jellyseerr" =
          SSL
          // {
            locations."/".proxyPass = "http://localhost:5055";
            serverAliases = ["jellyseer.home.jameshollowell.com"];
          };
      };
    };
  };
}
