with builtins;
with import ./wrench.nix;
# with import (
#   builtins.fetchurl {
#     url = "https://raw.githubusercontent.com/StijnRuts/nix-wrench/7a664ffc4f9dd25bfcde718f9285242c8bf52e81/wrench.nix";
#     sha256 = "sha256:1sgn66arsy0hpqzdrnv8j5p9cgwcqrgh9zx007qxi5v2x4x66kzl";
#   }
# );
rec {
  __functor =
    _:
    apply [
      module.load
      (project [
        shells
      ])
    ];

  module = {
    __functor =
      _:
      apply [
        (attrs.key.fold {
          inputs = value.keep.key;
          outputs = value.keep.key;
          _rest = attrs.key.singleton "outputs";
        })
        (attrs.key.over "outputs" to.function)
      ];

    load = over.type {
      path = p: module.load (import p);
      list = l: merge.list (map module.load l);
      attrs = module;
    };
  };

  project =
    f:
    (attrs.key.over "outputs" (
      over.function (
        inputs:
        attrs.key.fold {
          project =
            _: project:
            let
              project_systems = attrs.key.extract "systems" project;
              wPkgs = withPkgs inputs project_systems.value;
            in
            apply2 f wPkgs project_systems.rest;
        }
      )
    ));

  shells = {
    __functor =
      _: wPkgs:
      apply [
        #shells.default
        (attrs.key.fold {
          shells = _: [
            (over.attrs [
              to.function
              #(over.function (apply2 [
              #  shells.processes
              #  shells.scripts
              #]))
              #(over.function (
              #  pkgs:
              #  apply2 [
              #    shells.processes
              #    shells.scripts
              #  ] pkgs
              #)
              (lift.function [
                # TODO
                shells.processes
                shells.scripts
              ])
              #(over.function (
              #  pkgs:
              #  apply [
              #    (shells.processes pkgs)
              #    (shells.scripts pkgs)
              #  ]
              #))
            ])
            (shells: wPkgs (pkgs: over.attrs (shell: pkgs.mkShell (shell pkgs)) shells))
            (attrs.key.singleton "devShells")
          ];
        })
      ];

    # TODO
    default = attrs.key.fold {
      shell = value.to.path "shells.default";
    };

    processes =
      pkgs:
      attrs.key.fold {
        processes = _: processes: {
          scripts = apply [
            (over.attrs (
              config:
              "${pkgs.bash}/bin/bash -c '${pkgs.process-compose}/bin/process-compose --no-server -f ${
                pkgs.writers.writeYAML "process-compose.yaml" {
                  version = "0.5";
                  is_strict = true;
                  processes = config;
                }
              }'"
            ))
            (over.attrs2 (name: attrs.key.singleton "up:${name}"))
          ] processes;
        };
      };

    scripts =
      pkgs:
      attrs.key.fold {
        scripts = _: [
          (mapAttrs pkgs.writeShellScriptBin)
          attrValues
          (attrs.key.singleton "packages")
        ];
      };
  };

  #nixosConfigurations = {
  #  system = conf.system.arch;
  #  modules = [ ];
  #}

  perSystem =
    systems: getValue:
    listToAttrs (
      builtins.map (system: {
        name = system;
        value = getValue system;
      }) systems
    );

  withPkgs =
    inputs: systems: getValue:
    perSystem systems (system: getValue inputs.nixpkgs.legacyPackages.${system});
}
