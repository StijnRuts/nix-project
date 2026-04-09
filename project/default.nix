let
  recursive = import (
    builtins.fetchurl {
      url = "https://raw.githubusercontent.com/StijnRuts/nix-recursive-merge/4a3077519c121a9b67ec5e6141c488564e8a3041/recursive.nix";
      sha256 = "sha256:1pmp8vz2qsxnm4dbd34kahpgrdmfp1r2v03r77p0gw1k1764nppz";
    }
  );
in
parts:
with builtins;
let
  config = recursive.mergeList (map reifyModule (parts ++ (import ./modules.nix)));

  reifyModule = x: if isPath x then reifyModule (import x) else reifyOutputs x;

  reifyOutputs =
    x:
    if hasAttr "outputs" x then
      x // { outputs = reifyConfig x.outputs; }
    else
      { outputs = reifyConfig x; };

  reifyConfig =
    x:
    if isFunction x then
      i: reifyConfig (x i)
    else if hasAttr "config" x then
      x
    else
      { config = x; };
in
{
  inputs = config.inputs // {
    conflake = {
      url = "github:ratson/conflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = inputs: inputs.conflake ./. (params: config.outputs (inputs // params));
}
