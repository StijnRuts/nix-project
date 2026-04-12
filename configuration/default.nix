{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  outputs = {
    project = {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      shells =
        { pkgs, ... }:
        {
          default = {
            packages = [ pkgs.hello ];
            shellHook = "echo Started dev shell";
          };
        };
    };
  };
}
