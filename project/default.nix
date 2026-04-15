with builtins;
with import (
  builtins.fetchurl {
    url = "https://raw.githubusercontent.com/StijnRuts/nix-wrench/7a664ffc4f9dd25bfcde718f9285242c8bf52e81/wrench.nix";
    sha256 = "sha256:1sgn66arsy0hpqzdrnv8j5p9cgwcqrgh9zx007qxi5v2x4x66kzl";
  }
);
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
        inputs: outputs:
        (attrs.key.fold {
          project =
            _: project:
            let
              project_systems = attrs.key.extract "systems" project;
              wPkgs = withPkgs inputs project_systems.value;
            in
            apply2 f wPkgs project_systems.rest;
          _rest = value.keep;
        })
          outputs
      )
    ));

  shells = {
    __functor =
      _: wPkgs:
      apply [
        #shells.default
        (attrs.key.fold {
          shells = _: [
            #(over.attrs [
            #shells.processes
            #shells.scripts
            #])
            (shells: wPkgs (pkgs: over.attrs (shell: pkgs.mkShell (shell pkgs)) shells))
            (attrs.key.singleton "devShells")
          ];
        })
      ];
    #default = attrs.key.fold {
    #  shell = value.toPath "shells.default";
    #  _rest = value.keep;
    #};
    #processes = throw "todo";
    #scripts = throw "todo";
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
