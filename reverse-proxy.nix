{config, ...}: {
  config = {
    security.acme = {
      acceptTerms = true;
      defaults.email = "jamesthollowell@gmail.com";
      certs = let cloudflare_dns_chalenge = {
        dnsProvider = "cloudflare";
        # Have to specify an external resolver, otherwise LEGO (the ACME client) thinks `home.jameshollowell.com` is a valid zone.
        # See https://github.com/traefik/traefik/issues/3585 and https://github.com/go-acme/lego/issues/570
        dnsResolver = "1.1.1.1:53";
        environmentFile = config.age.secrets."cloudflare-dns-challenge".path;
      }; in {
        "jellyfin.home.jameshollowell.com" = cloudflare_dns_chalenge;
        "jellyseerr.home.jameshollowell.com" = cloudflare_dns_chalenge;
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = let
        SSL = {
          addSSL = true;
          enableACME = true;
          acmeRoot = null;
        };
      in {
        "jellyfin.home.jameshollowell.com" =
          SSL
          // {
            locations."/".proxyPass = "http://localhost:8096";
          };
        "jellyseerr.home.jameshollowell.com" =
          SSL
          // {
            locations."/".proxyPass = "http://localhost:5055";
          };
      };
    };
  };
}
