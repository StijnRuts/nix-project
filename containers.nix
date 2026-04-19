with builtins;
let
  chain = fs: val: foldl' (v: f: f v) val fs;

  shorten =
    n:
    chain [
      (split "[aeiou]")
      (filter isString)
      (concatStringsSep "")
      (substring 0 n)
    ];

  containername = project: env: "${shorten 6 project}-${shorten 3 env}";

  name = containername "myproject" "development";
  flake = "dev";
  hostIp = "10.233.1.1";
  localIp = "10.233.1.2";
in
{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      process-compose.dev = {
        settings.processes = {
          start = {
            namespace = name;
            description = "Create and start container ${name}";
            command = pkgs.writeShellApplication {
              name = "${name}-start";
              text = ''
                if sudo nixos-container status ${name} >/dev/null 2>&1; then
                  echo "Updating container ${name}"
                  sudo nixos-container update ${name} --flake .#${flake}
                else
                  echo "Creating container ${name}"
                  sudo nixos-container create ${name} --flake .#${flake} --host-address ${hostIp} --local-address ${localIp}
                fi

                sudo nixos-container start ${name}
                echo "Container ${name} is $(sudo nixos-container status ${name})"
              '';
            };
            is_daemon = true;
            readiness_probe.exec.command = "[ $(sudo nixos-container status ${name}) = 'up' ]";
            shutdown.command = "sudo nixos-container stop ${name}";
          };

          update = {
            namespace = name;
            description = "Update ${name} on *.nix changes";
            command =
              "echo 'Watching for changes to the container configuration...'"
              + " && ${lib.getExe pkgs.watchexec} --postpone --exts nix -- sudo nixos-container update ${name} --flake .#${flake}";
            depends_on.start.condition = "process_healthy";
          };

          shell = {
            namespace = name;
            description = "Root shell into the container";
            command = "sudo nixos-container root-login ${name}";
            is_foreground = true;
            depends_on.start.condition = "process_healthy";
          };
        };
      };
    };
}
