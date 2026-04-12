# Do not modify! This file is generated.
# One exception: If you use a different template than "flake.in.nix" set
#                its relative path through the first argument to inputs.flakegen.

{
  inputs = {
    flakegen.url = "github:jorsn/flakegen";
    nixlib.url = "github:nix-community/nixpkgs.lib";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  outputs = inputs: inputs.flakegen ./flake.in.nix inputs;
}