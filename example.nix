{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  devShell.packages = { pkgs }: [ pkgs.hello ];
}
