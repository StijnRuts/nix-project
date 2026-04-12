{
  systems = [
    "x86_64-linux"
    "x86_64-darwin"
    "aarch64-linux"
    "aarch64-darwin"
  ];
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  outputs =
    { nixpkgs, perSystem, ... }:
    {
      devShells = perSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.hello ];
            shellHook = "echo Started dev shell";
          };
        }
      );
    };
}
