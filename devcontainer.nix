{ self, ... }:
{
  easy-hosts = {
    shared.modules = [
      (
        { pkgs, ... }:
        {
          services.caddy = {
            enable = true;
            virtualHosts.myproject = {
              extraConfig = ''
                encode

                handle {
                  reverse_proxy localhost:8001
                }

                # handle_path {
                #   root ${self.packages.${pkgs.stdenv.hostPlatform.system}.frontend}
                #   file_server
                # }

                # handle_errors {
                #   root ${self.packages.${pkgs.stdenv.hostPlatform.system}.frontend}
                #   rewrite /error.html
                #   templates
                #   file_server
                # }
              '';
            };
          };

          networking.firewall.allowedTCPPorts = [
            80
            443
          ];
        }
      )
    ];

    hosts.dev = {
      modules = [
        (
          { pkgs, lib, ... }:
          {
            networking.hostName = "myproject-dev";
            system.stateVersion = "25.11";

            services.caddy = {
              virtualHosts.myproject = {
                serverAliases = [ "myproject-dev.local" ];
              };
            };

            users.users.dev = {
              isNormalUser = true;
              uid = 2000;
              group = "users";
            };

            systemd.services.frontend-dev = {
              enable = true;
              after = [ "network.target" ];
              wantedBy = [ "default.target" ];
              serviceConfig = {
                Type = "simple";
                User = "dev";
                Group = "users";
                ExecStart = "${lib.getExe pkgs.simple-http-server} --port 8001";
                WorkingDirectory = "/srv/frontend/public";
              };
            };
          }
        )
      ];
      tags = [ "container" ];
      # preproduction, release
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
