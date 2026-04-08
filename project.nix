let
  lib = import "${
    fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/nixos-25.11.tar.gz";
      sha256 = "sha256:1vs1g86i75rgpsvs7kyqfv22j6x3sg3daf4cv6ws3d0ghkb2ggpz";
    }
  }/lib";
in
parts:
let
  resolvePaths = builtins.map (x: if builtins.isPath x then import x else x);
  mergeList = sets: lib.foldl' lib.recursiveUpdate { } sets;
  config = mergeList (resolvePaths parts);
in
{
  inputs = config.inputs // {
    conflake = {
      url = "github:ratson/conflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: inputs.conflake ./. config.conflake;
}
