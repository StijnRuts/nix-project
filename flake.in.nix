(import ./project) [
  {
    project.formatters = _: {
      programs = {
        prettier.enable = true;
      };
    };
  }
  ./example.nix
]
