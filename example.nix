{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  conflake.devShell.packages = { pkgs }: [ pkgs.hello ];
}
