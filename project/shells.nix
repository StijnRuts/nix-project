let
  recursive = import (
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StijnRuts/nix-recursive-merge/4a3077519c121a9b67ec5e6141c488564e8a3041/recursive.nix";
      sha256 = "sha256:1pmp8vz2qsxnm4dbd34kahpgrdmfp1r2v03r77p0gw1k1764nppz";
    }
  );

  chain = fs: arg: builtins.foldl' (x: f: f x) arg fs;

  moveAttr =
    fromKey: toKey: f: attrs:
    recursive.merge (builtins.removeAttrs attrs [ fromKey ]) { ${toKey} = f attrs.${fromKey}; };

  reifyShell = chain [
    processesToScripts
    scriptsToPackages
  ];

  processesToScripts = moveAttr "processes" "scripts" (
    processes: args:
    builtins.mapAttrs (
      _: config:
      "${args.pkgs.process-compose}/bin/process-compose --no-server -f ${
        args.pkgs.writers.writeYAML "process-compose.yaml" {
          version = "0.5";
          is_strict = true;
          processes = config;
        }
      }"
    ) (processes args)
  );

  scriptsToPackages = moveAttr "scripts" "packages" (
    scripts: args: builtins.attrValues (builtins.mapAttrs args.pkgs.writeShellScriptBin (scripts args))
  );
in
{
  outputs =
    { lib, config, ... }:
    {
      options.project = {
        shell = lib.mkOption {
          type = lib.types.anything;
          default = lib.mkDefault { };
        };
        shells = lib.mkOption {
          type = lib.types.anything;
          default = lib.mkDefault { };
        };
      };

      config = {
        project.shells.default = config.project.shell;

        devShells = lib.mkMerge [
          (builtins.mapAttrs (_: reifyShell) config.project.shells)
        ];
      };
    };
}
