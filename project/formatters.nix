{
  inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      lib,
      config,
      treefmt-nix,
      ...
    }:
    {
      options.project.formatters = lib.mkOption {
        type = lib.types.anything;
        default = _: { };
      };

      config = {
        presets.formatters.enable = false;

        project.formatters = {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            statix.enable = true;
            deadnix.enable = true;
          };
        };

        perSystem =
          { pkgs, ... }:
          let
            treefmt = treefmt-nix.lib.evalModule pkgs config.project.formatters;
          in
          {
            formatter = treefmt.config.build.wrapper;
            checks.formatting = treefmt.config.build.check self;
          };
      };
    };
}
