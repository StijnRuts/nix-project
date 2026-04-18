with builtins;
with import ./wrench.nix;
# with import (
#   builtins.fetchurl {
#     url = "https://raw.githubusercontent.com/StijnRuts/nix-wrench/7a664ffc4f9dd25bfcde718f9285242c8bf52e81/wrench.nix";
#     sha256 = "sha256:1sgn66arsy0hpqzdrnv8j5p9cgwcqrgh9zx007qxi5v2x4x66kzl";
#   }
# );

# chain.functions to.function to.list over.list over.list.merge over.attrs over.attrs.merge

{
  __functor =
    self:
    self.module.load (
      self.module.reify (
        self.outputs (
          self.project (
            self.shells [
              self.processes
              self.scripts
            ]
          )
        )
      )
    );

  module = {
    load =
      f: m:
      if isAttrs m then
        apply f m
      else if isList m then
        merge.list (map module.load m)
      else if isPath m then
        module.load (import m)
      else
        throw "Tried to load module of unsupported type ${typeOf m}";

    reify =
      f: config:
      apply f {
        inherit (config) inputs;
        outputs = to.function (
          merge config.outputs (
            removeAttrs config [
              "inputs"
              "outputs"
            ]
          )
        );
      };
  };

  outputs = f: config: {
    outputs = inputs: apply2 f { inherit inputs; } (config.outputs inputs);
  };

  project =
    f: args: config:
    apply2 f (args // { inherit (config.project) systems; }) config;

  shells = {
    __functor =
      self: f:
      apply [
        self.defaultShell
        (self.reify f)
        self.mkShell
      ];

    defaultShell = _: config: {
      shells.default = config.shell;
    };

    reify =
      f: args: config:
      over.attrs (name: shellfn: {
        shells.${name} = over.function (pkgs: shell: apply2 f (args // { inherit pkgs; }) shell) (
          to.function shellfn
        );
      }) config.shells;

    mkShell =
      args: config:
      over.list (
        system:
        over.attrs (name: shellfn: {
          devShells.${system}.${name} =
            let
              pkgs = args.inputs.nixpkgs.legacyPackages.${system};
            in
            pkgs.mkShell (shellfn (args // { inherit pkgs; }));
        }) config.shells
      ) config.project.systems;
  };

  processes =
    { pkgs, ... }:
    config:
    over.attrs (name: processes: {
      scripts."up:${name}" = "${pkgs.process-compose}/bin/process-compose --no-server -f ${
        pkgs.writers.writeYAML "process-compose.yaml" {
          version = "0.5";
          is_strict = true;
          inherit processes;
        }
      }";
    }) config.processes;

  scripts =
    { pkgs, ... }:
    config:
    over.attrs (name: script: {
      packages = pkgs.writeShellScriptBin name script;
    }) config.scripts;
}
