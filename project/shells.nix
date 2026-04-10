let
  recursive = import (
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StijnRuts/nix-recursive-merge/4a3077519c121a9b67ec5e6141c488564e8a3041/recursive.nix";
      sha256 = "sha256:1pmp8vz2qsxnm4dbd34kahpgrdmfp1r2v03r77p0gw1k1764nppz";
    }
  );

  moveAttr =
    fromKey: toKey: f: attrs:
    recursive.merge (builtins.removeAttrs attrs [ fromKey ]) { ${toKey} = f attrs.${fromKey}; };

  reifyShellConfig = scriptsToPackages;

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
          (builtins.mapAttrs (_: reifyShellConfig) config.project.shells)
        ];
      };
    };
}
