let
  config = import ./example.nix;

  perSystem =
    systems: getValue:
    builtins.listToAttrs (
      builtins.map (system: {
        name = system;
        value = getValue system;
      }) systems
    );
in
{
  inherit (config) inputs;
  outputs = inputs: config.outputs (inputs // { perSystem = perSystem config.systems; });
}
