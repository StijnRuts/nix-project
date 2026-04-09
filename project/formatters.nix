let
  config = _: {
    projectRootFile = "flake.nix";
    programs = {
      nixfmt.enable = true;
      statix.enable = true;
      deadnix.enable = true;
    };
  };
in
{
  inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { self, treefmt-nix, ... }:
    {
      presets.formatters.enable = false;

      perSystem =
        { pkgs, ... }:
        let
          treefmt = treefmt-nix.lib.evalModule pkgs config;
        in
        {
          formatter = treefmt.config.build.wrapper;
          checks.formatting = treefmt.config.build.check self;
        };
    };
}
