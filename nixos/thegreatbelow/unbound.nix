{ config, ... }:
let
  cfg = config.thegreatbelow;
in
{
  # This is queried by the Fritzbox to obtain local addresses for this machine at *.xieve.net.
  # All other non-local domains have rebind protection by the Fritzbox.
  services.unbound = {
    enable = true;
    settings = {
      server =
        let
          interface = [
            "lo"
            "eno1"
            "tailscale0"
          ];
        in
        {
          inherit interface;
          interface-action = map (i: "${i} allow") interface;
          # Based on recommended settings in https://docs.pi-hole.net/guides/dns/unbound/#configure-unbound
          harden-glue = true;
          harden-dnssec-stripped = true;
          use-caps-for-id = false;
          prefetch = true;
          edns-buffer-size = 1232;

          interface-view = [
            "lo local"
            "eno1 local"
            "tailscale0 tailscale"
          ];
        };
      view =
        let
          local-zone = [
            ''"xieve.net." redirect''
            ''"cloud.xieve.net." transparent''
          ];
        in
        [
          {
            inherit local-zone;
            name = "local";
            local-data = [
              ''"xieve.net. 60 IN A ${cfg.ipAddress.v4}"''
              ''"xieve.net. 60 IN AAAA ${cfg.ipAddress.v6}"''
            ];
          }
          {
            inherit local-zone;
            name = "tailscale";
            local-data = [
              ''"xieve.net. 60 IN A 100.67.195.13"''
              ''"xieve.net. 60 IN AAAA fd7a:115c:a1e0::b601:c30d"''
            ];
          }
        ];
      forward-zone = [
        {
          name = ".";
          forward-addr = [
            "9.9.9.9#dns.quad9.net"
            "149.112.112.112#dns.quad9.net"
            "2620:fe::fe#dns.quad9.net"
            "2620:fe::9#dns.quad9.net"
          ];
          forward-tls-upstream = true; # DNS over TLS
        }
      ];
    };
  };
}
