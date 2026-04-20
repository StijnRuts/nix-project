{
  easy-hosts = {
    shared.modules = [
      {
        services.caddy = {
          enable = true;
          virtualHosts.myproject = {
            extraConfig = ''
              encode
              handle_path /api/* {
                respond "This is the API"
                # reverse_proxy localhost:9000
              }
              handle {
                root /srv/frontend
                file_server
              }
              handle_errors {
                root /srv/frontend
                rewrite /error.html
                templates
                file_server
              }
            '';
          };
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];
      }
    ];

    hosts.dev = {
      modules = [
        {
          networking.hostName = "myproject-dev";
          system.stateVersion = "25.11";

          services.caddy = {
            virtualHosts.myproject = {
              serverAliases = [ "myproject-dev.local" ];
            };
          };
        }
      ];
      tags = [ "container" ];
    };

    perTag =
      let
        tags = {
          container = {
            boot.isNspawnContainer = true;
            networking.useDHCP = false;

            services.avahi = {
              enable = true;
              publish = {
                enable = true;
                addresses = true;
              };
            };
          };
        };
      in
      tag: { modules = [ tags.${tag} ]; };
  };
}
