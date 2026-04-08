{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    conflake = {
      url = "github:ratson/conflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    inputs:
    inputs.conflake ./. {
      inherit inputs;
      devShell.packages = { pkgs }: [ pkgs.hello ];
    };
}
