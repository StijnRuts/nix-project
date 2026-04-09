# Do not modify! This file is generated.
# One exception: If you use a different template than "flake.in.nix" set
#                its relative path through the first argument to inputs.flakegen.

{
  inputs = {
    conflake = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:ratson/conflake";
    };
    flakegen.url = "github:jorsn/flakegen";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
  };
  outputs = inputs: inputs.flakegen ./flake.in.nix inputs;
}