{
  config,
  pkgs,
  ...
}: let
  tailscaleName = "nixos-media.buffalo-catfish.ts.net";
  tailscaleCertDir = "/var/lib/ts-cert";
in {
  config = {
    networking.firewall.allowedTCPPorts = [80 443];
    security.acme = {
      acceptTerms = true;
      defaults.email = "jamesthollowell@gmail.com";
      certs = let
        cloudflare_dns_chalenge = {
          dnsProvider = "cloudflare";
          # Have to specify an external resolver, otherwise LEGO (the ACME client) thinks `home.jameshollowell.com` is a valid zone.
          # See https://github.com/traefik/traefik/issues/3585 and https://github.com/go-acme/lego/issues/570
          dnsResolver = "1.1.1.1:53";
          environmentFile = config.age.secrets."cloudflare-dns-challenge".path;
        };
      in {
        "jellyfin.home.jameshollowell.com" = cloudflare_dns_chalenge;
        "jellyseerr.home.jameshollowell.com" = cloudflare_dns_chalenge;
      };
    };

    # create a oneshot job to authenticate to Tailscale
    systemd = {
      tmpfiles.settings.tailscaleCertDir = {
        "${tailscaleCertDir}"."d" = {
          mode = "750";
          user = "root";
          group = config.services.nginx.group;
        };
      };
      services.tailscale-cert = {
        description = "Create Tailscale TLS certificate";

        # make sure tailscale is running before trying to connect to tailscale
        after = ["network-pre.target" "tailscale.service"];
        wants = ["network-pre.target" "tailscale.service"];

        # set this service as a oneshot job
        serviceConfig.Type = "oneshot";

        # have the job run this shell script
        script = with pkgs; ''
          # wait for tailscaled to settle
          sleep 2

          # set -e gets automatically prepended, we need to not do that here
          set +e
          # check if out certificate is expiring in the next 30 days (or doesn't exist yet)
          ${openssl}/bin/openssl x509 -noout -in ${tailscaleCertDir}/${tailscaleName}.crt -checkend 2592000
          if [ $? -eq 0 ]; then # if so, then do nothing
            echo "Cert is good"
            exit 0
          fi
          set -e
          echo "Certificate either does not exist or is expiring, renewing..."

          # otherwise get a new cert from tailscale
          ${tailscale}/bin/tailscale cert --cert-file ${tailscaleCertDir}/${tailscaleName}.crt --key-file ${tailscaleCertDir}/${tailscaleName}.key ${tailscaleName}
          echo "Done! Setting permissions..."
          # Make the key group readable (by default only, it's 600)
          ${coreutils}/bin/chmod g+r ${tailscaleCertDir}/${tailscaleName}.key
          # Make the Nginx group the owner of both the key and cert so it can see them
          ${coreutils}/bin/chgrp ${config.services.nginx.group}  ${tailscaleCertDir}/${tailscaleName}.crt ${tailscaleCertDir}/${tailscaleName}.key
          echo "Done!"
        '';
      };
    };
    systemd.timers.tailscale-cert-autorenew = {
      wantedBy = ["timers.target"];
      timerConfig = {
        #The following example starts once a day (at 12:00am). When activated, it triggers the service immediately if it missed the last start time (option Persistent=true), for example due to the system being powered off.
        OnCalendar = "daily";
        Persistent = true;
        Unit = "tailscale-cert.service";
      };
    };

    services.nginx = {
      enable = true;
      virtualHosts = let
        acmeSSL = {
          addSSL = true;
          enableACME = true;
          acmeRoot = null;
        };
        tailscaleSsl = {
          addSSL = true;
          sslCertificate = "${tailscaleCertDir}/${tailscaleName}.crt";
          sslCertificateKey = "${tailscaleCertDir}/${tailscaleName}.key";
        };
        jellyfinProxyPass = {
          locations."/" =  {
            proxyPass = "http://localhost:8096";
            proxyWebsockets = true;
          };
        };
      in {
        "jellyfin.home.jameshollowell.com" = acmeSSL // jellyfinProxyPass;
        "jellyseerr.home.jameshollowell.com" =
          acmeSSL
          // {
            locations."/".proxyPass = "http://localhost:5055";
          };
        "${tailscaleName}" = tailscaleSsl // jellyfinProxyPass;
      };
    };
  };
}
