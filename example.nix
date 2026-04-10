{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };

  outputs = {
    project.shell = {
      packages = { pkgs, ... }: [ pkgs.hello ];
      scripts =
        { pkgs, ... }:
        {
          lorem = "echo ipsum";
        };
    };
  };
}
