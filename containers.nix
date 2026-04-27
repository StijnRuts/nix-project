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
  hostPath = "./frontend";
  containerPath = "/srv/frontend";
in
{ lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      container = pkgs.writeShellApplication {
        name = "container";
        runtimeInputs = [
          pkgs.nixos-container
          pkgs.watchexec
        ];
        text = builtins.readFile ./container.sh;
      };
      containerBin = lib.getExe container;
    in
    {
      packages.container = container;
      devshells.default.packages = [ container ];

      process-compose.dev = {
        settings.processes = {
          start = {
            namespace = name;
            description = "Create container, start, and keep updated ${name}";
            command = builtins.concatStringsSep " && " [
              "${containerBin} build ${name} ${flake}"
              "${containerBin} mount ${name} ${hostPath} ${containerPath}"
              "${containerBin} up ${name}"
              "${containerBin} watch ${name} ${flake} --live"
            ];
            is_daemon = true;
            readiness_probe.exec.command = "${containerBin} status ${name}";
            shutdown.command = builtins.concatStringsSep " && " [
              "${containerBin} down ${name}"
              "${containerBin} umount ${name} ${containerPath}"
            ];
          };

          shell = {
            namespace = name;
            description = "Root shell into the container";
            command = "${containerBin} shell ${name}";
            is_foreground = true;
            depends_on.start.condition = "process_healthy";
          };
        };
      };
    };
}
