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
      shell = pkgs: { packages = [ pkgs.cmatrix ]; };
      shells = {
        other = pkgs: {
          packages = [ pkgs.hello ];
          scripts = {
            lorem = "echo ipsum";
          };
          processes = {
            dev = {
              server.command = "while true; do echo running...; sleep 2; done";
            };
          };
          shellHook = "echo Started dev shell";
        };
      };
    };
  };
}
