{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs.devShell.packages =
    { pkgs }:
    [
      pkgs.hello
    ];
}
