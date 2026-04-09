(import ./project) [
  {
    outputs.config.project.formatters = _: {
      programs = {
        prettier.enable = true;
      };
    };
  }
  ./example.nix
]
