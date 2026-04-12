{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixlib.url = "github:nix-community/nixpkgs.lib";
  };
  outputs =
    { nixpkgs, ... }:
    {
      packages.x86_64-linux.hello = nixpkgs.legacyPackages.x86_64-linux.hello;
    };

}
